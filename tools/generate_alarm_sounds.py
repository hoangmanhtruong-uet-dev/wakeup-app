#!/usr/bin/env python3
"""
Sinh bộ nhạc chuông cho WakeUp+ dưới dạng file WAV thật.

Vì sao cần script này?
- Yêu cầu F-04 trong docs/REQUIREMENTS.md cần "10-15 nhạc chuông".
- Tài nguyên `assets/` của Flutter KHÔNG nằm trong iOS bundle, nên
  `UNNotificationSound(named:)` sẽ trả về nil và iOS rơi về âm mặc định.
  Vì vậy file .wav phải được đưa vào **bundle iOS** (ios/Runner/) và vào
  Android qua `res/raw/` hoặc assets.

Chạy lại sau khi đổi thiết kế âm thanh:
    python tools/generate_alarm_sounds.py

Chỉ dùng thư viện chuẩn của Python (wave, math, struct, random) để không
phải cài thêm gói.

Thông số kỹ thuật:
- 22050 Hz, 16 bit, mono.
  Đủ cho âm thanh tổng hợp (biên độ tần số ~11 kHz) và giữ dung lượng nhỏ
  — yêu cầu phi chức năng giới hạn bản cài < 40 MB.
- Mỗi file có fade-in/fade-out để không bị tiếng "cụp" khi lặp.
- Chuẩn hoá đỉnh về -1.0 dBFS để không bị clipping khi phát to.
"""

import math
import os
import random
import struct
import sys
import wave

# Windows console mặc định dùng cp1258, in tiếng Việt sẽ vỡ.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SAMPLE_RATE = 22050
BIT_DEPTH = 16
MAX_AMPLITUDE = 32767


# --------------------------------------------------------------------------
# Tiện ích tín hiệu
# --------------------------------------------------------------------------

def sine(freq, t):
    """Sóng sin cơ bản."""
    return math.sin(2.0 * math.pi * freq * t)


def square(freq, t, duty=0.5):
    """Sóng vuông. duty = tỉ lệ thời gian ở mức cao."""
    phase = (freq * t) % 1.0
    return 1.0 if phase < duty else -1.0


def sawtooth(freq, t):
    """Sóng nước cưa trong khoảng [-1, 1]."""
    return 2.0 * ((freq * t) % 1.0) - 1.0


def triangle(freq, t):
    """Sóng tam giác, mềm hơn sóng vuông nên nghe "ấm" hơn."""
    phase = (freq * t) % 1.0
    if phase < 0.5:
        return 4.0 * phase - 1.0
    return 3.0 - 4.0 * phase


def noise():
    """Nhiễu trắng, dùng cho âm thanh kiểu còi/chuông gõ."""
    return random.uniform(-1.0, 1.0)


def env_ad(t, total, attack=0.01, decay=None, sustain=0.7, release=0.15):
    """Bao hình ADSR đơn giản theo thời gian chuẩn hoá (0..1)."""
    if t < attack:
        return t / attack
    if decay is not None and t < attack + decay:
        x = (t - attack) / decay
        return 1.0 + (sustain - 1.0) * x
    release_start = max(attack, (total * (1.0 - release)))
    if t > release_start:
        return sustain * max(0.0, 1.0 - (t - release_start) / (release * total + 1e-9))
    return sustain


def env_exp_decay(t, tau):
    """Suy giảm mũ - mô phỏng chuông gõ (công suất tụ điện tải)."""
    return math.exp(-t / tau)


def apply_soft_clip(x):
    """Giới hạn mềm để tránh méo tiếng khi cộng nhiều thành phần."""
    return math.tanh(x)


def fade_edges(samples, seconds=0.02):
    """Fade-in/fade-out để khi lặp không bị tiếng đột ngột."""
    n = min(int(SAMPLE_RATE * seconds), len(samples) // 2)
    if n <= 0:
        return samples
    out = list(samples)
    for i in range(n):
        g = i / n
        out[i] *= g
        out[-1 - i] *= g
    return out


def normalize(samples, peak=0.92):
    """Chuẩn hoá đỉnh về `peak` (-0.7 dBFS) để không clipping."""
    m = max((abs(s) for s in samples), default=0.0)
    if m < 1e-9:
        return samples
    k = peak / m
    return [s * k for s in samples]


def remove_dc(samples):
    """Loại bỏ thành phần DC (trung bình khác 0).

    Vì sao cần? Với sóng vuông duty cycle lệch (ví dụ 35%), trung bình tín hiệu là
    -0.30. Thành phần DC này **lãng phí headroom**, khiến loa bị "đẩy" và có thể
    tạo tiếng cộc khi bật/tắt. Audio chuẩn luôn đi qua bộ lọc chặn DC.

    Các âm thanh ở đây đều tuần hoàn, nên trừ trung bình cho kết quả chính xác tuyệt đối.
    """
    if not samples:
        return samples
    mean = sum(samples) / len(samples)
    return [s - mean for s in samples]


def render(duration, sample_fn):
    """Tạo mảng mẫu từ hàm sample_fn(t) -> float trong khoảng [-1, 1]."""
    n = int(SAMPLE_RATE * duration)
    return [sample_fn(i / SAMPLE_RATE) for i in range(n)]


def write_wav(path, samples):
    """Ghi mảng float [-1,1] ra file WAV 16 bit mono."""
    pcm = bytearray()
    for s in samples:
        v = int(s * MAX_AMPLITUDE)
        if v > MAX_AMPLITUDE:
            v = MAX_AMPLITUDE
        elif v < -MAX_AMPLITUDE - 1:
            v = -MAX_AMPLITUDE - 1
        pcm += struct.pack('<h', v)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(BIT_DEPTH // 8)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(bytes(pcm))


# --------------------------------------------------------------------------
# Định nghĩa từng nhạc chuông
# --------------------------------------------------------------------------
# Mỗi hàm trả về (duration, hàm sinh mẫu).

def make_default():
    """Chuông mặc định: hai nốt A -> E ngắn, quen thuộc nhất."""
    def f(t):
        # Vòng lặp 1.2s: nốt 880Hz rồi 1320Hz
        cyc = t % 1.2
        if cyc < 0.22:
            return 0.85 * apply_soft_clip(sine(880.0, cyc) + 0.3 * sine(1760.0, cyc))
        if cyc < 0.34:
            return 0.0
        if cyc < 0.56:
            return 0.85 * apply_soft_clip(sine(1320.0, cyc) + 0.3 * sine(2640.0, cyc))
        return 0.0
    return 4.8, f


def make_beep():
    """Chuông bíp gắt, tần số cao, báo động mạnh."""
    def f(t):
        cyc = t % 0.6
        if cyc < 0.16:
            g = min(1.0, cyc / 0.005)
            return 0.9 * g * apply_soft_clip(square(2000.0, cyc, 0.35))
        return 0.0
    return 3.6, f


def make_radar():
    """Chuông radar: xung ngắn, tần số chậm rãi, quen tai nhất cho việc báo thức."""
    def f(t):
        cyc = t % 1.0
        if cyc < 0.30:
            # Hồi quy tần số trong mỗi xung -> nghe như "pip"
            freq = 620.0 + 500.0 * (cyc / 0.30)
            g = env_exp_decay(cyc, 0.22)
            return 0.9 * g * apply_soft_clip(sine(freq, cyc))
        return 0.0
    return 5.0, f


def make_siren():
    """Còi xe cứu hỏa: nước lên rồi nước xuống, chu kỳ 3.6 giây."""
    def f(t):
        cyc = t % 3.6
        # Quét tần số hình sin: 600Hz -> 1200Hz -> 600Hz
        freq = 900.0 + 300.0 * math.sin(2.0 * math.pi * cyc / 3.6)
        g = min(1.0, cyc / 0.05) * min(1.0, (3.6 - cyc) / 0.15)
        return 0.8 * g * apply_soft_clip(triangle(freq, cyc))
    return 7.2, f


def make_bell():
    """Chuông gõ: nhiều hoạ âm với suy giảm khác nhau -> nghe như chuông thật.

    Hệ số hoạ âm 2.76 / 5.40 / 8.93 là tỉ lệ hoạ âm điển hình của một quả chuông gõ
    (không phải bội số nguyên) — đó là lý do nghe chuông khác chuông bíp.

    Thời gian suy giảm phải NGẮN HƠN chu kỳ gõ (0.75s), nếu không mỗi nhát chưa tắt hẳn
    đã chồng lên nhát sau và cả bản thành một tiếng ù liên tục, mất hẳn cảm giác "gõ".
    """
    partials = [(1.0, 1.0), (2.76, 0.55), (5.40, 0.32), (8.93, 0.18)]
    base_tau = 0.24  # < 0.75s để các nhát tách bạch, không chồng tiếng

    def f(t):
        cyc = t % 0.75
        v = 0.0
        for ratio, amp in partials:
            # Hoạ âm càng cao tắt càng nhanh
            v += amp * env_exp_decay(cyc, base_tau / ratio) * sine(880.0 * ratio, cyc)
        return 0.85 * apply_soft_clip(v)
    return 6.0, f


def make_birds():
    """Chim hót: các cú chirp tần số biến đổi nhanh, thức dậy tự nhiên."""
    chirps = [(0.00, 0.14, 2600), (0.26, 0.11, 3100), (0.45, 0.16, 2200),
              (0.72, 0.12, 3400), (0.95, 0.14, 2800)]

    def f(t):
        cyc = t % 1.5
        v = 0.0
        for start, dur, freq in chirps:
            if start <= cyc < start + dur:
                local = cyc - start
                x = local / dur
                # Tần số trượt lên rồi trượt xuống trong mỗi cú chirp
                f0 = freq * (1.0 + 0.25 * math.sin(math.pi * x))
                g = math.sin(math.pi * x)  # bao hình hình sin -> mềm, không "cụp"
                v += g * apply_soft_clip(sine(f0, local) + 0.2 * sine(f0 * 2, local))
        return 0.7 * v
    return 4.5, f


def make_arpeggio():
    """Hợp âm đi lên rồi đi xuống, dễ chịu và dễ nhận."""
    notes = [523.25, 659.25, 783.99, 1046.50]  # C5 E5 G5 C6
    note_len = 0.2
    period = 1.6   # 4 nốt x 0.2s = 0.8s, còn lại là khoảng lặng

    def f(t):
        cyc = t % period
        idx = int(cyc / note_len)
        # Hết 4 nốt -> im hẳn.
        #
        # KHÔNG dùng `min(idx, 3)`: khi đó idx=3 sẽ kéo dài tới hết chu kỳ và
        # `local` vượt quá độ dài nốt, khiến `(note_len - local)` thành số ÂM ->
        # hệ số bao hình đảo dấu, nghe thành tiếng méo.
        if idx >= len(notes):
            return 0.0

        local = cyc - idx * note_len
        g = min(1.0, local / 0.01) * min(1.0, (note_len - local) / 0.04)
        freq = notes[idx]
        return 0.8 * g * apply_soft_clip(
            sine(freq, local) + 0.45 * sine(freq * 2, local) + 0.2 * sine(freq * 3, local)
        )
    return 4.8, f


def make_buzzer():
    """Còi gắt: sóng vuông cứng + nhiễu nhẹ, nghe 'chói' nhất."""
    def f(t):
        cyc = t % 0.5
        if cyc < 0.28:
            g = min(1.0, cyc / 0.005) * min(1.0, (0.28 - cyc) / 0.03)
            v = square(1046.50, cyc, 0.5) * 0.6 + square(1567.98, cyc, 0.5) * 0.3
            v += noise() * 0.06
            return 0.85 * g * apply_soft_clip(v)
        return 0.0
    return 4.0, f


def make_chime():
    """Chuông gió nhẹ nhàng, hợp với người thích dậu nhẹ."""
    def f(t):
        cyc = t % 2.0
        g = env_exp_decay(cyc, 1.5)
        v = sine(1046.50, cyc) * 0.6 + sine(1318.51, cyc) * 0.3
        return 0.7 * g * apply_soft_clip(v)
    return 6.0, f


def make_wakeup():
    """Hai nốt thân thiện kiểu 'dậy đi', dễ nhận ngay cả khi mới ngủ."""
    def f(t):
        cyc = t % 1.8
        if cyc < 0.45:
            g = min(1.0, cyc / 0.01) * min(1.0, (0.45 - cyc) / 0.06)
            return 0.8 * g * apply_soft_clip(sine(587.33, cyc) + 0.3 * sine(1174.66, cyc))
        if cyc < 0.75:
            g = min(1.0, (cyc - 0.45) / 0.01) * min(1.0, (0.75 - cyc) / 0.06)
            return 0.8 * g * apply_soft_clip(sine(880.00, cyc) + 0.3 * sine(1760.00, cyc))
        return 0.0
    return 5.4, f


def make_digital():
    """Chuông kiểu đồng hồ số / game cũ, gợi cảm giác 'báo giờ'."""
    def f(t):
        cyc = t % 0.8
        if cyc < 0.35:
            g = min(1.0, cyc / 0.004)
            v = square(1244.51, cyc, 0.5) * 0.7
            return 0.75 * g * apply_soft_clip(v)
        return 0.0
    return 4.0, f


def make_sunrise():
    """Tăng dần từ từ — mô phỏng 'bình minh' nêu trong roadmap."""
    def f(t):
        cyc = t % 6.0
        x = cyc / 6.0
        # Tần số và biên độ cùng tăng dần trong 6 giây
        freq = 220.0 + 700.0 * x
        amp = 0.25 + 0.65 * x
        g = min(1.0, cyc / 0.2)
        v = sine(freq, cyc) + 0.35 * sine(freq * 1.5, cyc)
        return amp * g * apply_soft_clip(v)
    return 6.0, f


SOUNDS = {
    "alarm_default": make_default,
    "alarm_beep": make_beep,
    "alarm_radar": make_radar,
    "alarm_siren": make_siren,
    "alarm_bell": make_bell,
    "alarm_birds": make_birds,
    "alarm_arpeggio": make_arpeggio,
    "alarm_buzzer": make_buzzer,
    "alarm_chime": make_chime,
    "alarm_wakeup": make_wakeup,
    "alarm_digital": make_digital,
    "alarm_sunrise": make_sunrise,
}


def main():
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "assets", "sounds")
    os.makedirs(out_dir, exist_ok=True)

    total = 0
    for name, factory in sorted(SOUNDS.items()):
        duration, fn = factory()
        samples = render(duration, fn)
        samples = remove_dc(samples)
        samples = normalize(fade_edges(samples))
        path = os.path.join(out_dir, name + ".wav")
        write_wav(path, samples)
        size = os.path.getsize(path)
        total += size
        print("  {0:<20} {1:>5.1f}s  {2:>7.1f} KB".format(name, duration, size / 1024.0))

    print("\nTong: {0} file, {1:.1f} MB -> {2}".format(
        len(SOUNDS), total / (1024.0 * 1024.0), out_dir))


if __name__ == "__main__":
    main()