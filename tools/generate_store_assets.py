"""
Script to generate store assets for WakeUp+:
1. Google Play Store icon (512x512, RGB no alpha)
2. Google Play Feature Graphic (1024x500, RGB no alpha)
3. Apple App Store icon (1024x1024, RGB no alpha)
4. Formatted store screenshots:
   - store/google-play/tablet-7in/ (1200x1920 RGB)
   - store/google-play/tablet-10in/ (1600x2560 RGB)
   - store/app-store/iphone-6.9in/ (1320x2868 RGB)
   - store/app-store/iphone-6.7in/ (1290x2796 RGB)
   - store/app-store/ipad-13in/ (2064x2752 RGB)
"""

import os
import glob
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS_DIR = os.path.join(ROOT_DIR, "assets", "images")
STORE_DIR = os.path.join(ROOT_DIR, "store")
PHONE_DIR = os.path.join(STORE_DIR, "google-play", "phone")

# Brand colors
BG_MAIN = (14, 17, 26)         # #0E111A
BG_CARD = (24, 29, 42)         # #181D2A
WARM_SUN = (255, 193, 143)     # #FFC18F
NEON_MINT = (56, 235, 214)     # #38EBD6
TEXT_WHITE = (255, 255, 255)
TEXT_MUTED = (142, 149, 165)

def get_font(font_name: str, size: int):
    system_font_paths = [
        os.path.join("C:/Windows/Fonts", font_name),
        os.path.join("C:/Windows/Fonts", "segoeuib.ttf"),
        os.path.join("C:/Windows/Fonts", "arialbd.ttf"),
    ]
    for p in system_font_paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()

def generate_store_icons():
    master_icon_path = os.path.join(ASSETS_DIR, "app_icon.png")
    if not os.path.exists(master_icon_path):
        raise FileNotFoundError(f"Master app icon not found at: {master_icon_path}")

    master_icon = Image.open(master_icon_path).convert("RGBA")

    # 1. Google Play 512x512 (RGB, no alpha)
    gp_icon_dir = os.path.join(STORE_DIR, "google-play", "icon")
    os.makedirs(gp_icon_dir, exist_ok=True)
    gp_icon_path = os.path.join(gp_icon_dir, "ic_launcher-512.png")

    gp_img = Image.new("RGBA", (512, 512), BG_MAIN + (255,))
    resized_512 = master_icon.resize((512, 512), Image.Resampling.LANCZOS)
    gp_img = Image.alpha_composite(gp_img, resized_512).convert("RGB")
    gp_img.save(gp_icon_path, "PNG", optimize=True)
    print(f"Generated Google Play 512x512 icon: {gp_icon_path}")

    # 2. App Store 1024x1024 (RGB, no alpha)
    as_icon_dir = os.path.join(STORE_DIR, "app-store", "app-icon")
    os.makedirs(as_icon_dir, exist_ok=True)
    as_icon_path = os.path.join(as_icon_dir, "AppIcon-1024.png")

    as_img = Image.new("RGBA", (1024, 1024), BG_MAIN + (255,))
    as_img = Image.alpha_composite(as_img, master_icon).convert("RGB")
    as_img.save(as_icon_path, "PNG", optimize=True)
    print(f"Generated App Store 1024x1024 icon: {as_icon_path}")

def generate_feature_graphic():
    w, h = 1024, 500
    base = Image.new("RGBA", (w, h), BG_MAIN + (255,))

    # Ambient radial lighting
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    # Warm light behind icon
    glow_draw.ellipse([80, 50, 480, 450], fill=(255, 193, 143, 60))
    # Mint glow behind text
    glow_draw.ellipse([500, 100, 950, 420], fill=(56, 235, 214, 45))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=60))
    base = Image.alpha_composite(base, glow)

    # Place app icon on the left
    master_icon_path = os.path.join(ASSETS_DIR, "app_icon.png")
    master_icon = Image.open(master_icon_path).convert("RGBA")
    icon_size = 350
    icon_resized = master_icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    icon_x = 75
    icon_y = (h - icon_size) // 2
    base.alpha_composite(icon_resized, (icon_x, icon_y))

    # Decorative frame for icon
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Right side typography
    title_font = get_font("segoeuib.ttf", 64)
    subtitle_font = get_font("segoeuib.ttf", 24)
    tagline_font = get_font("segoeui.ttf", 20)
    badge_font = get_font("segoeuib.ttf", 15)

    tx = 470
    ty = 85

    # App Title "WakeUp+"
    draw.text((tx, ty), "WakeUp", font=title_font, fill=TEXT_WHITE)
    # Calculate offset for "+" symbol
    title_bbox = draw.textbbox((tx, ty), "WakeUp", font=title_font)
    plus_x = title_bbox[2] + 4
    draw.text((plus_x, ty), "+", font=title_font, fill=NEON_MINT)

    # Subtitle
    ty_sub = ty + 78
    draw.text((tx, ty_sub), "BÁO THỨC CHÍNH XÁC & BẢO VỆ THỨC GIẤC", font=subtitle_font, fill=WARM_SUN)

    # Tagline
    ty_tag = ty_sub + 38
    draw.text((tx, ty_tag), "Kêu đúng giờ 99.9% • Nhiệm vụ thức dậy • Không quảng cáo", font=tagline_font, fill=TEXT_MUTED)

    # Divider bar
    ty_div = ty_tag + 42
    draw.line([(tx, ty_div), (tx + 480, ty_div)], fill=(255, 255, 255, 40), width=2)
    # Mint accent on divider
    draw.line([(tx, ty_div), (tx + 120, ty_div)], fill=NEON_MINT, width=2)

    # 3 Feature Pills
    badges = [
        ("✓ Chuông Bền Bỉ", WARM_SUN),
        ("✓ Nhiệm Vụ Toán", NEON_MINT),
        ("✓ Mã Hóa AES-256", TEXT_WHITE),
    ]
    pill_y = ty_div + 24
    curr_px = tx
    for text, col in badges:
        bb = draw.textbbox((curr_px, pill_y), text, font=badge_font)
        pw = (bb[2] - bb[0]) + 24
        ph = 32
        pill_rect = [curr_px, pill_y, curr_px + pw, pill_y + ph]
        draw.rounded_rectangle(pill_rect, radius=16, fill=BG_CARD, outline=(255, 255, 255, 30), width=1)
        draw.text((curr_px + 12, pill_y + 6), text, font=badge_font, fill=col)
        curr_px += pw + 12

    base = Image.alpha_composite(base, overlay).convert("RGB")
    fg_dir = os.path.join(STORE_DIR, "google-play", "feature-graphic")
    os.makedirs(fg_dir, exist_ok=True)
    fg_path = os.path.join(fg_dir, "feature_graphic.png")
    base.save(fg_path, "PNG", optimize=True)
    print(f"Generated Feature Graphic: {fg_path} (1024x500 RGB)")

def create_rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size[0] - 1, size[1] - 1)], radius=radius, fill=255)
    return mask

def format_tablet_screen(src_img: Image.Image, canvas_w: int, canvas_h: int, corner_radius: int) -> Image.Image:
    # Scale proportionally to fit ~92% height
    target_h = int(canvas_h * 0.91)
    target_w = int(target_h * (src_img.width / src_img.height))
    
    # In case target_w exceeds 88% width
    if target_w > int(canvas_w * 0.88):
        target_w = int(canvas_w * 0.88)
        target_h = int(target_w * (src_img.height / src_img.width))

    resized_screen = src_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    screen_mask = create_rounded_mask((target_w, target_h), corner_radius)

    canvas = Image.new("RGBA", (canvas_w, canvas_h), BG_MAIN + (255,))

    # Ambient soft glow on canvas
    cx = canvas_w // 2
    cy = canvas_h // 2
    glow = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    g_draw.ellipse([cx - target_w // 2, cy - target_h // 2, cx + target_w // 2, cy + target_h // 2],
                   fill=(56, 235, 214, 25))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=60))
    canvas = Image.alpha_composite(canvas, glow)

    # Frame position
    pos_x = (canvas_w - target_w) // 2
    pos_y = (canvas_h - target_h) // 2

    # Drop shadow
    shadow = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([pos_x - 6, pos_y - 4, pos_x + target_w + 6, pos_y + target_h + 16],
                             radius=corner_radius + 4, fill=(0, 0, 0, 140))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=20))
    canvas = Image.alpha_composite(canvas, shadow)

    # Paste framed screenshot with rounded mask
    canvas.paste(resized_screen, (pos_x, pos_y), screen_mask)

    # Border stroke
    border_layer = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(border_layer)
    b_draw.rounded_rectangle([pos_x, pos_y, pos_x + target_w - 1, pos_y + target_h - 1],
                             radius=corner_radius, outline=(255, 255, 255, 50), width=2)
    canvas = Image.alpha_composite(canvas, border_layer)

    return canvas.convert("RGB")

def format_and_copy_screenshots():
    phone_files = sorted(glob.glob(os.path.join(PHONE_DIR, "*.png")))
    if not phone_files:
        raise FileNotFoundError(f"No phone screenshots found in: {PHONE_DIR}")

    targets = {
        "iphone_6_9": {
            "dir": os.path.join(STORE_DIR, "app-store", "iphone-6.9in"),
            "size": (1320, 2868),
            "mode": "direct_lanczos",
        },
        "iphone_6_7": {
            "dir": os.path.join(STORE_DIR, "app-store", "iphone-6.7in"),
            "size": (1290, 2796),
            "mode": "direct_lanczos",
        },
        "ipad_13": {
            "dir": os.path.join(STORE_DIR, "app-store", "ipad-13in"),
            "size": (2064, 2752),
            "mode": "framed_tablet",
            "corner_radius": 36,
        },
        "tablet_7in": {
            "dir": os.path.join(STORE_DIR, "google-play", "tablet-7in"),
            "size": (1200, 1920),
            "mode": "framed_tablet",
            "corner_radius": 24,
        },
        "tablet_10in": {
            "dir": os.path.join(STORE_DIR, "google-play", "tablet-10in"),
            "size": (1600, 2560),
            "mode": "framed_tablet",
            "corner_radius": 32,
        },
    }

    for t_info in targets.values():
        os.makedirs(t_info["dir"], exist_ok=True)

    for src_path in phone_files:
        base_name = os.path.basename(src_path)
        with Image.open(src_path) as src_img:
            src_img = src_img.convert("RGBA")

            for t_name, t_info in targets.items():
                out_path = os.path.join(t_info["dir"], base_name)
                tw, th = t_info["size"]

                if t_info["mode"] == "direct_lanczos":
                    # Direct Lanczos resize to standard iPhone dimensions
                    resized = src_img.resize((tw, th), Image.Resampling.LANCZOS).convert("RGB")
                    resized.save(out_path, "PNG", optimize=True)
                elif t_info["mode"] == "framed_tablet":
                    # Proportional frame for tablet and iPad aspect ratios
                    framed = format_tablet_screen(src_img, tw, th, t_info["corner_radius"])
                    framed.save(out_path, "PNG", optimize=True)

                print(f"[{t_name}] Saved: {out_path} ({tw}x{th} RGB)")

def main():
    print("=== Generating Store Assets for WakeUp+ ===")
    generate_store_icons()
    generate_feature_graphic()
    format_and_copy_screenshots()
    print("=== All Store Assets Successfully Generated! ===")

if __name__ == "__main__":
    main()
