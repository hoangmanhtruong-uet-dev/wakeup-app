#!/usr/bin/env python3
"""
Đăng ký thư mục âm thanh vào Xcode project (project.pbxproj).

## Vì sao cần script này?
File .wav nằm trong `assets/` của Flutter sẽ KHÔNG được đóng gói vào app iOS.
`UNNotificationSound(named:)` và `Bundle.main.url(forResource:)` chỉ tìm được file
nằm trong **app bundle**. Vì vậy âm thanh phải nằm trong `ios/Runner/Sounds/` và
được khai báo trong Xcode > "Copy Bundle Resources".

Sửa tay project.pbxproj cho 12 file tốn 36 mục (FileReference + BuildFile + Group +
Resources phase) — rất dễ sót hoặc trùng ID. Script này làm tự động và **idempotent**
(chạy lại nhiều lần cũng không nhân bản).

Chạy:
    python tools/register_ios_sounds.py
"""

import os
import re
import sys

# Windows console mặc định dùng cp1258, in tiếng Việt sẽ vỡ.
# Bắt buộc stdout dùng UTF-8 trước khi in.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBXPROJ = os.path.join(ROOT, "ios", "Runner.xcodeproj", "project.pbxproj")
SOUNDS_DIR = os.path.join(ROOT, "ios", "Runner", "Sounds")
GROUP_ID = "CF00000000000000000000A1"
GROUP_NAME = "Sounds"
# Phase Resources của target Runner (không phải RunnerTests).
RUNNER_RESOURCES_ID = "97C146EC1CF9000F007C117D"


def file_ref_id(i):
    return "CF000000000000000000%04X" % i


def build_file_id(i):
    return "CF100000000000000000%04X" % i


def main():
    if not os.path.isfile(PBXPROJ):
        print("Không tìm thấy %s" % PBXPROJ)
        return 1

    if not os.path.isdir(SOUNDS_DIR):
        print("Không có thư mục %s - hãy chạy generate_alarm_sounds.py trước." % SOUNDS_DIR)
        return 1

    wavs = sorted(f for f in os.listdir(SOUNDS_DIR) if f.lower().endswith(".wav"))
    if not wavs:
        print("Thư mục %s không có file .wav nào." % SOUNDS_DIR)
        return 1

    with open(PBXPROJ, "r", encoding="utf-8") as fh:
        text = fh.read()

    if GROUP_ID in text:
        print("Thư mục '%s' đã được đăng ký trong Xcode project - không làm gì." % GROUP_NAME)
        return 0

    # ---- 1. PBXBuildFile ----
    build_lines = []
    for i, name in enumerate(wavs):
        build_lines.append(
            "\t\t%s /* %s in Resources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };\n"
            % (build_file_id(i), name, file_ref_id(i), name)
        )
    text = text.replace(
        "/* End PBXBuildFile section */",
        "".join(build_lines) + "/* End PBXBuildFile section */",
        1,
    )

    # ---- 2. PBXFileReference ----
    ref_lines = []
    for i, name in enumerate(wavs):
        ref_lines.append(
            "\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = audio.wav; "
            "path = %s; sourceTree = \"<group>\"; };\n" % (file_ref_id(i), name, name)
        )
    text = text.replace(
        "/* End PBXFileReference section */",
        "".join(ref_lines) + "/* End PBXFileReference section */",
        1,
    )

    # ---- 3. Nhóm Sounds ----
    children = "".join(
        "\t\t\t\t%s /* %s */,\n" % (file_ref_id(i), name) for i, name in enumerate(wavs)
    )
    group_block = (
        "\t\t%s /* %s */ = {\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        "%s"
        "\t\t\t);\n"
        "\t\t\tpath = %s;\n"
        "\t\t\tsourceTree = \"<group>\";\n"
        "\t\t};\n" % (GROUP_ID, GROUP_NAME, children, GROUP_NAME)
    )
    text = text.replace("/* End PBXGroup section */", group_block + "/* End PBXGroup section */", 1)

    # ---- 4. Gắn nhóm Sounds vào nhóm Runner ----
    runner_anchor = "\t\t\t\tAB03000000000000000000E1 /* AlarmPlugin.swift */,\n"
    if runner_anchor not in text:
        print("Không tìm thấy điểm gắn nhóm Runner trong pbxproj.")
        return 1
    text = text.replace(
        runner_anchor,
        runner_anchor + "\t\t\t\t%s /* %s */,\n" % (GROUP_ID, GROUP_NAME),
        1,
    )

    # ---- 5. Thêm vào Resources build phase của Runner ----
    res_anchor = (
        "\t\t97C146EC1CF9000F007C117D /* Resources */ = {\n"
        "\t\t\tisa = PBXResourcesBuildPhase;\n"
        "\t\t\tbuildActionMask = 2147483647;\n"
        "\t\t\tfiles = (\n"
    )
    if res_anchor not in text:
        print("Không tìm thấy Resources build phase của target Runner.")
        return 1
    res_entries = "".join(
        "\t\t\t\t%s /* %s in Resources */,\n" % (build_file_id(i), name)
        for i, name in enumerate(wavs)
    )
    text = text.replace(res_anchor, res_anchor + res_entries, 1)

    with open(PBXPROJ, "w", encoding="utf-8") as fh:
        fh.write(text)

    print("Đã đăng ký %d file âm thanh vào Xcode project:" % len(wavs))
    for name in wavs:
        print("  - %s" % name)
    print("\nLưu ý: sau khi build, các file .wav sẽ nằm ở bundle và có thể được")
    print("UNNotificationSound(named:) / Bundle.main.url(forResource:) tìm thấy.")
    return 0


if __name__ == "__main__":
    sys.exit(main())