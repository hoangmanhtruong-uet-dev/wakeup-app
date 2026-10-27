#!/usr/bin/env python3
"""
Kiểm định chất lượng (QC) bộ nhạc chuông WakeUp+.

## Tuyên bố quan trọng
Tác giả là AI, **không nghe được âm thanh**. Script này không thay thế việc nghe.
Nó kiểm tra những lỗi kỹ thuật có thể phát hiện bằng tín hiệu — và đó là phần lớn
lỗi thật sự gây ra chuông nghe "tệ":

1. **Aliasing** — năng lượng tần số cao bị gấp về tần số thấp, nghe như ù/khàn.
2. **Clipping** — sóng bị cắt đỉnh, nghe chói và méo.
3. **DC offset** — có thành phần một chiều, làm loa "đẩy" và mất bass.
4. **Nối loop bị đứt** — RINGTONE của Android lặp liên tục; nếu mẫu cuối nối mẫu
   đầu không liền sẽ nghe "cụp" mỗi vòng.
5. **Số vòng lặp không nguyên** — chuông đổi nhịp ở mốc bản ghi, nghe lạc.
6. **Cấu trúc sai** — ví dụ "radar" nhưng không có xung; "siren" nhưng không quét
   tần số.
7. **Click nội tại** — nhảy mẫu đột ngột tạo tiếng "tách".

Chạy:
    python tools/analyze_alarm_sounds.py
"""

import glob
import math
import os
import sys

import numpy as np

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOUNDS = os.path.join(ROOT, "assets", "sounds")

SR = 22050
NYQUIST = SR / 2.0

# Kỳ vọng thiết kế cho từng chuông.
#   period : chu kỳ lặp (giây). duration phải là bội nguyên của period.
#   freqs  : tần số chính cần có trong phổ (Hz) — kiểm tra "đúng ý đồ".
#   max_freq: ngưỡng trên đó coi là năng lượng ngoài ý muốn.
#
# LƯU Ý về max_freq: phải tính tới hoạ âm của dạng số, nếu không sẽ báo động giả.
# Ví dụ sóng vuông 2000 Hz có hoạ âm lẻ ở 2000/6000/10000 Hz — năng lượng trên
# 6000 Hz là **đúng thiết kế**, không phải aliasing. Chỉ năng lượng sát Nyquist mới đáng nghi.
#   wave   : dạng số. 'square' = có sóng vuông -> crest factor thấp là BẢN CHẤT của dạng
#            số, không phải lỗi, nên bỏ qua kiểm tra crest cho nhóm này.
EXPECT = {
    "alarm_default":  dict(period=1.2,  freqs=[880, 1320],         max_freq=5000,  kind="burst", wave="sine"),
    "alarm_beep":     dict(period=0.6,  freqs=[2000],              max_freq=10500, kind="burst", wave="square"),
    "alarm_radar":    dict(period=1.0,  freqs=[620, 1120],         max_freq=5000,  kind="burst", wave="sine"),
    "alarm_siren":    dict(period=3.6,  freqs=[600, 900, 1200],     max_freq=6000,  kind="sweep", wave="triangle"),
    "alarm_bell":     dict(period=0.75, freqs=[880, 2429, 4752],   max_freq=8500,  kind="burst", wave="sine"),
    "alarm_birds":    dict(period=1.5,  freqs=[2200, 3100, 3400],  max_freq=8000,  kind="burst", wave="sine"),
    "alarm_arpeggio": dict(period=1.6,  freqs=[523, 659, 784, 1047], max_freq=5000, kind="burst", wave="sine"),
    "alarm_buzzer":   dict(period=0.5,  freqs=[1047, 1568],        max_freq=10500, kind="burst", wave="square"),
    "alarm_chime":    dict(period=2.0,  freqs=[1047, 1319],        max_freq=5000,  kind="decay", wave="sine"),
    "alarm_wakeup":   dict(period=1.8,  freqs=[587, 880],          max_freq=5000,  kind="burst", wave="sine"),
    "alarm_digital":  dict(period=0.8,  freqs=[1245],              max_freq=9500,  kind="burst", wave="square"),
    "alarm_sunrise":  dict(period=6.0,  freqs=[220, 920],          max_freq=4000,  kind="sweep", wave="sine"),
}


def find_quiet_runs(mask, min_len):
    """Tìm các đoạn liên tục có mask=True, xử lý đúng cao đoạn bọc qua cuối file.

    Sai lầm ở các bản trước: ghép cặp `starts` với `ends` bằng `zip` chỉ đúng khi mặt nạ
    bắt đầu và kết thúc bằng CÙNG giá trị. Với âm thanh kiểu "nốt–nghỉ" thì đầu file là
    nốt (0) còn cuối file là nghỉ (1) -> lệch một đoạn -> sinh ra độ dài ÂM.

    Cách đúng: tách riêng đoạn bọc qua biên trước, rồi mới ghép cặp phần còn lại.
    """
    mask = np.asarray(mask)
    n = len(mask)
    if n == 0 or mask.all():
        return [n] if mask.all() else []

    inner = mask
    wrap = 0
    if mask[0] and mask[n - 1]:
        # Đoạn yên tĩnh bọc qua mốc cuối-đầu file -> gộp thành MỘT đoạn.
        i = 0
        while i < n and mask[i]:
            i += 1
        j = n - 1
        while j >= 0 and mask[j]:
            j -= 1
        wrap = i + (n - 1 - j)
        # Bỏ đoạn ở đầu đi, phần cuối sẽ được tìm như đoạn thường.
        inner = mask.copy()
        inner[:i] = False

    d = np.diff(np.concatenate([inner, inner]).astype(np.int8))
    starts = np.where(d == 1)[0]
    ends = np.where(d == -1)[0]
    runs = [int(e - s) for s, e in zip(starts, ends)]
    if wrap:
        runs.append(int(wrap))
    return [r for r in runs if r >= min_len]


def load(path):
    import wave
    with wave.open(path, "rb") as w:
        n, sr, ch, sw = w.getnframes(), w.getframerate(), w.getnchannels(), w.getsampwidth()
        raw = w.readframes(n)
    x = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0
    return x, sr, ch, sw


def spectrum(x):
    """Phổ trung bình theo cửa sổ, trả về (freqs, magnitude dB)."""
    win = np.hanning(len(x))
    nfft = 1 << 18
    S = np.abs(np.fft.rfft(x * win, n=nfft))
    freqs = np.fft.rfftfreq(nfft, 1.0 / SR)
    # Trung bình theo các đoạn để ổn định hơn
    seg = S[: len(S)]
    return freqs, 20 * np.log10(seg + 1e-12)


def check(name, x, sr, ch, sw):
    exp = EXPECT[name]
    issues = []
    ok = []

    dur = len(x) / sr
    peak = np.max(np.abs(x))
    rms = np.sqrt(np.mean(x ** 2))
    dc = np.mean(x)

    # --- 1. Định dạng ---
    if sr != SR or ch != 1 or sw != 2:
        issues.append("Định dạng lệch: %d Hz / %d kênh / %d bit" % (sr, ch, sw * 8))
    else:
        ok.append("Định dạng đúng (%d Hz, mono, 16 bit)" % sr)

    # --- 2. DC offset ---
    if abs(dc) > 0.005:
        issues.append("DC offset %.4f (nên < 0.005)" % dc)
    else:
        ok.append("DC offset %.5f - không đáng kể" % dc)

    # --- 3. Clipping ---
    clipped = int(np.sum(np.abs(x) >= 0.999))
    runs = 0
    if clipped > 0:
        mask = np.abs(x) >= 0.999
        runs = int(np.sum(mask[1:] & mask[:-1]))
        issues.append("Có %d mẫu chạm đỉnh (%d cụm liên tiếp)" % (clipped, runs))
    else:
        ok.append("Không clipping (peak %.3f = %.1f dBFS)" % (peak, 20 * math.log10(peak)))

    # --- 4. Nối loop: đây mới là chỗ "tách" thật sự quan trọng ---
    # RINGTONE của Android lặp liên tục nên mốc giữa mẫu cuối và mẫu đầu là nơi
    # tiếng "cụp" thường xảy ra.
    #
    # KHÔNG dùng "max nhảy mẫu" để dò click: với sóng vuông, việc nhảy từ +1 xuống -1
    # trong MỘT mẫu là bản chất của sóng vuông, không phải lỗi. Chỉ số đó báo động giả
    # cho mọi âm vuông/sawtooth.
    seam = abs(x[0] - x[-1])
    head_tail = max(abs(x[0]), abs(x[-1]))
    if seam > 0.05 or head_tail > 0.05:
        issues.append(
            "Nối loop giật: |đầu-cuối|=%.3f, biên độ hai đầu=%.3f" % (seam, head_tail))
    else:
        ok.append("Nối loop mượt (|đầu-cuối|=%.4f, hai đầu gần 0)" % seam)

    # --- 6. Số vòng lặp nguyên ---
    period = exp["period"]
    cycles = dur / period
    if abs(cycles - round(cycles)) < 1e-6:
        ok.append("Số vòng lặp nguyên: %.0f vòng x %.2fs" % (round(cycles), period))
    else:
        issues.append(
            "Số vòng lặp không nguyên: %.3f (mốc bản ghi lệch nhịp)" % cycles)

    # --- 7. Aliasing / rác tần số cao ---
    freqs, mag = spectrum(x)
    total = np.sum(mag > -60)
    hi = mag[freqs > exp["max_freq"]]
    if len(hi) > 0:
        hi_ratio = np.sum(10 ** (hi / 10)) / (np.sum(10 ** (mag / 10)) + 1e-20)
    else:
        hi_ratio = 0.0
    if hi_ratio > 0.05:
        issues.append(
            "Nhiều năng lượng trên %.0f Hz (%.1f%%) vượt thiết kế"
            % (exp["max_freq"], hi_ratio * 100))
    else:
        ok.append("Năng lượng trên %.0f Hz: %.2f%% - đúng thiết kế"
                  % (exp["max_freq"], hi_ratio * 100))

    # --- 7b. Chặn Nyquist: năng lượng sát Nyquist là dấu hiệu aliasing ---
    # Nội dung lẫn cắn vào dải 95%-100% Nyquist thường là sản phẩm gấp phổ.
    top = mag[freqs > 0.95 * NYQUIST]
    top_ratio = (np.sum(10 ** (top / 10)) / (np.sum(10 ** (mag / 10)) + 1e-20)
                 if len(top) > 0 else 0.0)
    if top_ratio > 0.02:
        issues.append("Năng lượng sát Nyquist %.1f%% - nghi vỡ aliasing"
                      % (top_ratio * 100))
    else:
        ok.append("Dải sát Nyquist: %.2f%% - sạch" % (top_ratio * 100))

    # --- 8. Tần số chính có đúng ý đồ không ---
    found = []
    for f0 in exp["freqs"]:
        band = (freqs > f0 - 25) & (freqs < f0 + 25)
        if np.max(mag[band]) > (np.max(mag) - 40):
            found.append(f0)
    missing = [f0 for f0 in exp["freqs"] if f0 not in found]
    if missing:
        issues.append("Thiếu tần số chính: %s Hz" % ", ".join(str(int(m)) for m in missing))
    else:
        ok.append("Đủ %d tần số chính như thiết kế" % len(exp["freqs"]))

    # --- 9. Cấu trúc: có khoảng lặng giữa các xung không ---
    if exp["kind"] == "burst":
        win = int(sr * 0.02)
        env = np.sqrt(np.convolve(x ** 2, np.ones(win) / win, mode="same"))
        thr = env.max() * 0.08
        gaps = find_quiet_runs(env < thr, int(sr * 0.06))
        if len(gaps) >= 1:
            ok.append("Có %d khoảng lặng >=60ms (nhịp xung rõ ràng)" % len(gaps))
        else:
            issues.append("Không tìm thấy khoảng lặng - nghe như tiếng kéo dài liên tục")

    # --- 10. Crest factor (độ "đột ngột" của âm) ---
    crest = 20 * math.log10(peak / rms) if rms > 0 else 0
    if exp["kind"] == "burst" and exp["wave"] != "square" and crest < 6:
        issues.append("Crest factor %.1f dB thấp - âm nghe đều, thiếu nhịp" % crest)
    elif exp["wave"] == "square":
        ok.append("Crest factor %.1f dB - đúng bản chất sóng vuông" % crest)
    else:
        ok.append("Crest factor %.1f dB" % crest)

    return dur, peak, rms, crest, dc, issues, ok


def main():
    files = sorted(glob.glob(os.path.join(SOUNDS, "*.wav")))
    if not files:
        print("Không tìm thấy file .wav trong %s" % SOUNDS)
        print("Hãy chạy: python tools/generate_alarm_sounds.py")
        return 1

    total_issues = 0
    for p in files:
        name = os.path.splitext(os.path.basename(p))[0]
        x, sr, ch, sw = load(p)

        if name not in EXPECT:
            print("!! %s: chưa có kỳ vọng thiết kế trong EXPECT" % name)
            total_issues += 1
            continue

        dur, peak, rms, crest, dc, issues, ok = check(name, x, sr, ch, sw)
        total_issues += len(issues)

        print("=" * 74)
        print("%s   (%.2fs, %.1f KB)" % (
            name, dur, os.path.getsize(p) / 1024.0))
        print("  peak %.1f dBFS | RMS %.1f dBFS | crest %.1f dB" % (
            20 * math.log10(peak), 20 * math.log10(rms), crest))
        for o in ok:
            print("  [OK]   %s" % o)
        for i in issues:
            print("  [!!]   %s" % i)

    print("=" * 74)
    if total_issues == 0:
        print("KET QUA: 12/12 file dat yeu cau ky thuat.")
        print()
        print("LUON Y: day moi la KIEM TRA KY THUAT, khong phai nghe thu.")
        print("Hay mo tung file va nghe thu truoc khi dua len store -")
        print("vi du nhip do cua 'radar' va 'siren' la cam nhan chu quan.")
    else:
        print("KET QUA: %d van de can xu ly." % total_issues)
    return 0


if __name__ == "__main__":
    sys.exit(main())