"""
Verification script for Milestone 5 deliverables:
Asserts file existence, dimensions, and image mode compliance.
"""

import os
import sys
from PIL import Image

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

CHECKS = [
    # 1. Master Icon
    ("assets/images/app_icon.png", (1024, 1024), None),

    # 2. Android Mipmaps
    ("android/app/src/main/res/mipmap-mdpi/ic_launcher.png", (48, 48), None),
    ("android/app/src/main/res/mipmap-hdpi/ic_launcher.png", (72, 72), None),
    ("android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", (96, 96), None),
    ("android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", (144, 144), None),
    ("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", (192, 192), None),

    # 3. iOS AppIcon
    ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png", (1024, 1024), "RGB"),

    # 4. Store Icons
    ("store/google-play/icon/ic_launcher-512.png", (512, 512), "RGB"),
    ("store/google-play/feature-graphic/feature_graphic.png", (1024, 500), "RGB"),
    ("store/app-store/app-icon/AppIcon-1024.png", (1024, 1024), "RGB"),
]

SCREENSHOT_DIRS = [
    ("store/google-play/tablet-7in", (1200, 1920), "RGB"),
    ("store/google-play/tablet-10in", (1600, 2560), "RGB"),
    ("store/app-store/iphone-6.9in", (1320, 2868), "RGB"),
    ("store/app-store/iphone-6.7in", (1290, 2796), "RGB"),
    ("store/app-store/ipad-13in", (2064, 2752), "RGB"),
]

EXPECTED_SCREENSHOTS = [
    "01_dashboard.png",
    "02_world_clock.png",
    "03_stopwatch.png",
    "04_sleep.png",
    "05_ringing.png",
    "07_login.png",
    "08_onboarding.png",
]

def run_verification():
    passed = 0
    total = 0

    print("=== Milestone 5 Asset Verification ===")

    # Check standalone assets
    for rel_path, expected_size, expected_mode in CHECKS:
        total += 1
        full_path = os.path.join(ROOT_DIR, rel_path)
        if not os.path.exists(full_path):
            print(f"[FAIL] Missing file: {rel_path}")
            sys.exit(1)
        
        with Image.open(full_path) as img:
            if img.size != expected_size:
                print(f"[FAIL] {rel_path}: size {img.size} != expected {expected_size}")
                sys.exit(1)
            if expected_mode and img.mode != expected_mode:
                print(f"[FAIL] {rel_path}: mode {img.mode} != expected {expected_mode}")
                sys.exit(1)
        
        print(f"[PASS] {rel_path} -> {expected_size} {expected_mode or ''}")
        passed += 1

    # Check screenshot directories
    for sdir, expected_size, expected_mode in SCREENSHOT_DIRS:
        for sname in EXPECTED_SCREENSHOTS:
            total += 1
            rel_path = os.path.join(sdir, sname)
            full_path = os.path.join(ROOT_DIR, rel_path)
            if not os.path.exists(full_path):
                print(f"[FAIL] Missing screenshot: {rel_path}")
                sys.exit(1)

            with Image.open(full_path) as img:
                if img.size != expected_size:
                    print(f"[FAIL] {rel_path}: size {img.size} != expected {expected_size}")
                    sys.exit(1)
                if expected_mode and img.mode != expected_mode:
                    print(f"[FAIL] {rel_path}: mode {img.mode} != expected {expected_mode}")
                    sys.exit(1)
            
            passed += 1
        print(f"[PASS] {sdir} -> all 7 screenshots match {expected_size} {expected_mode}")

    print(f"\nVerification SUCCESS: {passed}/{total} asset assertions passed!")

if __name__ == "__main__":
    run_verification()
