"""
Script to generate the master WakeUp+ app icon (1024x1024 PNG).
Adheres to WakeUp+ Brand Palette:
- Deep Background: #0E111A
- Warm Sun: #FFC18F
- Neon Mint: #38EBD6
- Card Background: #181D2A
- Pure White: #FFFFFF
"""

import math
import os
from PIL import Image, ImageDraw, ImageFilter

def create_master_icon(output_path: str, size: int = 1024):
    scale = 2  # 2x supersampling for high fidelity antialiasing
    w = size * scale
    h = size * scale
    cx = w // 2
    cy = int(h * 0.52)  # slightly shifted down for bells/handle balance

    # Colors (RGBA)
    BG_COLOR = (14, 17, 26, 255)         # #0E111A
    CARD_BG = (24, 29, 42, 255)          # #181D2A
    WARM_SUN = (255, 193, 143, 255)      # #FFC18F
    NEON_MINT = (56, 235, 214, 255)      # #38EBD6
    WHITE = (255, 255, 255, 255)
    MUTED = (142, 149, 165, 255)

    base = Image.new("RGBA", (w, h), BG_COLOR)

    # 1. Background Ambient Glows
    glow_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)

    # Warm sun glow at top center
    glow_draw.ellipse([cx - 450, cy - 550, cx + 450, cy + 350], fill=(255, 193, 143, 60))
    # Neon mint glow at bottom center
    glow_draw.ellipse([cx - 380, cy - 250, cx + 380, cy + 500], fill=(56, 235, 214, 45))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=80 * scale))
    base = Image.alpha_composite(base, glow_layer)

    # 2. Vector artwork layer
    art_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(art_layer)

    # Clock dimensions
    clock_radius = int(360 * scale)
    bell_radius_x = int(105 * scale)
    bell_radius_y = int(75 * scale)

    # Sound vibration waves emanating from bells
    def draw_arc_wave(center_x, center_y, r, start_ang, end_ang, color, width):
        bbox = [center_x - r, center_y - r, center_x + r, center_y + r]
        draw.arc(bbox, start=start_ang, end=end_ang, fill=color, width=width)

    # Left sound waves
    left_bell_cx = cx - int(290 * scale)
    left_bell_cy = cy - int(290 * scale)
    draw_arc_wave(left_bell_cx, left_bell_cy, int(150 * scale), 125, 235, (255, 193, 143, 140), int(10 * scale))
    draw_arc_wave(left_bell_cx, left_bell_cy, int(190 * scale), 135, 225, (255, 193, 143, 80), int(8 * scale))

    # Right sound waves
    right_bell_cx = cx + int(290 * scale)
    right_bell_cy = cy - int(290 * scale)
    draw_arc_wave(right_bell_cx, right_bell_cy, int(150 * scale), 305, 415, (56, 235, 214, 140), int(10 * scale))
    draw_arc_wave(right_bell_cx, right_bell_cy, int(190 * scale), 315, 405, (56, 235, 214, 80), int(8 * scale))

    # Feet (legs) at bottom
    foot_len = int(100 * scale)
    foot_width = int(24 * scale)
    for angle_deg, color in [(-135, WARM_SUN), (-45, NEON_MINT)]:
        rad = math.radians(angle_deg)
        start_x = cx + int((clock_radius - 15 * scale) * math.cos(rad))
        start_y = cy - int((clock_radius - 15 * scale) * math.sin(rad))
        end_x = cx + int((clock_radius + foot_len) * math.cos(rad))
        end_y = cy - int((clock_radius + foot_len) * math.sin(rad))
        draw.line([(start_x, start_y), (end_x, end_y)], fill=color, width=foot_width)
        # Foot cap
        draw.ellipse([end_x - foot_width, end_y - foot_width, end_x + foot_width, end_y + foot_width], fill=color)

    # Twin Bells & Hammer
    # Hammer base
    hammer_top = cy - int(410 * scale)
    draw.line([(cx, cy - clock_radius + int(20 * scale)), (cx, hammer_top)], fill=WHITE, width=int(16 * scale))
    draw.ellipse([cx - int(25 * scale), hammer_top - int(25 * scale), cx + int(25 * scale), hammer_top + int(25 * scale)], fill=WARM_SUN)

    # Draw angled bells
    def draw_bell(bx, by, angle_deg, color):
        # Create bell on separate rotated canvas
        bsize = int(300 * scale)
        bimg = Image.new("RGBA", (bsize, bsize), (0, 0, 0, 0))
        bdraw = ImageDraw.Draw(bimg)
        bcx = bsize // 2
        bcy = bsize // 2
        
        # Bell connector peg
        bdraw.rectangle([bcx - int(12 * scale), bcy, bcx + int(12 * scale), bcy + int(70 * scale)], fill=CARD_BG)
        # Bell dome (half ellipse)
        bbox = [bcx - bell_radius_x, bcy - bell_radius_y, bcx + bell_radius_x, bcy + bell_radius_y]
        bdraw.chord(bbox, start=180, end=360, fill=color, outline=WHITE, width=int(6 * scale))
        
        # Rotate
        rotated = bimg.rotate(angle_deg, resample=Image.Resampling.BICUBIC, center=(bcx, bcy))
        art_layer.alpha_composite(rotated, (bx - bcx, by - bcy))

    draw_bell(left_bell_cx, left_bell_cy, 45, WARM_SUN)
    draw_bell(right_bell_cx, right_bell_cy, -45, NEON_MINT)

    # Clock Outer Body (Shadow & Ring)
    # Outer glow ring
    for r_offset, alpha in [(30, 25), (20, 50), (10, 80)]:
        r = clock_radius + int(r_offset * scale)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(56, 235, 214, alpha), width=int(12 * scale))

    # Main clock bezel (gradient effect simulated by dual arcs)
    draw.ellipse([cx - clock_radius, cy - clock_radius, cx + clock_radius, cy + clock_radius], fill=CARD_BG)

    bezel_width = int(22 * scale)
    # Warm Sun on left/top, Neon Mint on right/bottom
    draw.arc([cx - clock_radius, cy - clock_radius, cx + clock_radius, cy + clock_radius],
             start=120, end=300, fill=WARM_SUN, width=bezel_width)
    draw.arc([cx - clock_radius, cy - clock_radius, cx + clock_radius, cy + clock_radius],
             start=300, end=480, fill=NEON_MINT, width=bezel_width)

    # Inner Dial Face
    inner_r = clock_radius - bezel_width
    dial_box = [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r]
    draw.ellipse(dial_box, fill=(18, 22, 34, 255))

    # Subtle Rising Sun inside dial (bottom half)
    sun_cy = cy + int(120 * scale)
    sun_r = int(180 * scale)
    # Sun rays
    for i in range(12):
        ray_deg = 180 + i * 15
        ray_rad = math.radians(ray_deg)
        x1 = cx + int((sun_r * 0.4) * math.cos(ray_rad))
        y1 = sun_cy + int((sun_r * 0.4) * math.sin(ray_rad))
        x2 = cx + int(sun_r * math.cos(ray_rad))
        y2 = sun_cy + int(sun_r * math.sin(ray_rad))
        draw.line([(x1, y1), (x2, y2)], fill=(255, 193, 143, 60), width=int(6 * scale))
    # Sun disk
    draw.chord([cx - sun_r // 2, sun_cy - sun_r // 2, cx + sun_r // 2, sun_cy + sun_r // 2],
               start=180, end=360, fill=(255, 193, 143, 160))

    # Dial Hour Marks
    tick_outer_r = inner_r - int(24 * scale)
    for hour in range(12):
        deg = hour * 30
        rad = math.radians(deg - 90)
        is_cardinal = (hour % 3 == 0)
        tick_len = int((28 if is_cardinal else 16) * scale)
        tick_w = int((10 if is_cardinal else 5) * scale)
        color = WARM_SUN if hour in (9, 12) else (NEON_MINT if hour in (3, 6) else MUTED)
        
        x_out = cx + int(tick_outer_r * math.cos(rad))
        y_out = cy + int(tick_outer_r * math.sin(rad))
        x_in = cx + int((tick_outer_r - tick_len) * math.cos(rad))
        y_in = cy + int((tick_outer_r - tick_len) * math.sin(rad))
        draw.line([(x_in, y_in), (x_out, y_out)], fill=color, width=tick_w)

    # Clock Hands: Set to 7:00 (optimal wake-up time!)
    # Hour hand (7 o'clock = 120 degrees clockwise from 12 o'clock, or 210 degrees from right)
    hour_ang = math.radians(210)
    hour_len = int(170 * scale)
    hx = cx + int(hour_len * math.cos(hour_ang))
    hy = cy + int(hour_len * math.sin(hour_ang))
    draw.line([(cx, cy), (hx, hy)], fill=WARM_SUN, width=int(22 * scale))

    # Minute hand (12 o'clock = 270 degrees / straight up)
    min_ang = math.radians(270)
    min_len = int(240 * scale)
    mx = cx + int(min_len * math.cos(min_ang))
    my = cy + int(min_len * math.sin(min_ang))
    draw.line([(cx, cy), (mx, my)], fill=NEON_MINT, width=int(16 * scale))

    # Center Cap Pivot
    draw.ellipse([cx - int(28 * scale), cy - int(28 * scale), cx + int(28 * scale), cy + int(28 * scale)], fill=WARM_SUN)
    draw.ellipse([cx - int(16 * scale), cy - int(16 * scale), cx + int(16 * scale), cy + int(16 * scale)], fill=NEON_MINT)
    draw.ellipse([cx - int(8 * scale), cy - int(8 * scale), cx + int(8 * scale), cy + int(8 * scale)], fill=WHITE)

    # 3. Floating "+" Symbol (WakeUp+)
    plus_cx = cx + int(310 * scale)
    plus_cy = cy - int(380 * scale)
    plus_size = int(50 * scale)
    plus_w = int(18 * scale)

    # Glowing back for plus
    plus_glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    pg_draw = ImageDraw.Draw(plus_glow)
    pg_draw.ellipse([plus_cx - plus_size * 2, plus_cy - plus_size * 2,
                     plus_cx + plus_size * 2, plus_cy + plus_size * 2], fill=(56, 235, 214, 100))
    plus_glow = plus_glow.filter(ImageFilter.GaussianBlur(radius=20 * scale))
    base = Image.alpha_composite(base, plus_glow)

    # Draw crisp "+"
    draw.line([(plus_cx - plus_size, plus_cy), (plus_cx + plus_size, plus_cy)], fill=NEON_MINT, width=plus_w)
    draw.line([(plus_cx, plus_cy - plus_size), (plus_cx, plus_cy + plus_size)], fill=NEON_MINT, width=plus_w)
    # Soft rounded endpoints
    r_cap = plus_w // 2
    for pt in [(plus_cx - plus_size, plus_cy), (plus_cx + plus_size, plus_cy),
               (plus_cx, plus_cy - plus_size), (plus_cx, plus_cy + plus_size)]:
        draw.ellipse([pt[0] - r_cap, pt[1] - r_cap, pt[0] + r_cap, pt[1] + r_cap], fill=NEON_MINT)

    # Merge vector art layer
    base = Image.alpha_composite(base, art_layer)

    # Downsample to target size with high-quality Lanczos resampling
    final_img = base.resize((size, size), Image.Resampling.LANCZOS)
    
    # Save as PNG
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    final_img.save(output_path, "PNG", optimize=True)
    print(f"Generated {size}x{size} app icon at: {output_path}")

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "images")
    target_file = os.path.join(out_dir, "app_icon.png")
    create_master_icon(target_file, 1024)
