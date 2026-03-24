#!/usr/bin/env python3
"""
Generates CricPulse app icon PNGs — cricket ball and cricket bat variants.
Run from the CricPulse root directory:
  python3 scripts/generate_icons.py
"""

from PIL import Image, ImageDraw
import os, math

SIZE = 1024
XCASSETS = "CricPulse/Assets.xcassets"

# ── Helpers ────────────────────────────────────────────────────────────────────

def gradient_bg(size, top_color, bot_color):
    """Fast vertical gradient via 1×size → resize."""
    strip = Image.new("RGBA", (1, size))
    for y in range(size):
        t = y / (size - 1)
        c = tuple(int(top_color[i] * (1 - t) + bot_color[i] * t) for i in range(3)) + (255,)
        strip.putpixel((0, y), c)
    return strip.resize((size, size), Image.BILINEAR)


def circle(draw, cx, cy, r, fill):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)


def arc(draw, cx, cy, r, start, end, fill, width):
    box = [cx - r, cy - r, cx + r, cy + r]
    draw.arc(box, start=start, end=end, fill=fill, width=width)


# ── Cricket Ball ───────────────────────────────────────────────────────────────

def draw_ball(img, ball_color, seam_color):
    draw = ImageDraw.Draw(img)
    cx = cy = SIZE // 2
    R = int(SIZE * 0.34)
    sw = max(6, int(SIZE * 0.022))

    # Drop shadow
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    off = int(R * 0.07)
    circle(sd, cx + off, cy + off, R, (0, 0, 0, 70))
    img = Image.alpha_composite(img, shadow)
    draw = ImageDraw.Draw(img)

    # Ball body
    circle(draw, cx, cy, R, ball_color)

    # Shine highlight
    shine_r = int(R * 0.22)
    shine_x = cx - int(R * 0.28)
    shine_y = cy - int(R * 0.28)
    circle(draw, shine_x, shine_y, shine_r, (*[min(255, c + 80) for c in ball_color[:3]], 110))

    # Seam arcs
    seam_r = int(R * 0.62)
    arc(draw, cx, cy, seam_r, 200, 340, seam_color, sw)
    arc(draw, cx, cy, seam_r, 20,  160, seam_color, sw)
    return img


# ── Cricket Bat ────────────────────────────────────────────────────────────────

def draw_bat(img, bat_color, grain_color, handle_color):
    draw = ImageDraw.Draw(img)
    cx = cy = SIZE // 2

    # Bat is angled ~35 degrees
    angle = math.radians(-35)
    cos_a, sin_a = math.cos(angle), math.sin(angle)

    def rot(x, y):
        return (cx + int(x * cos_a - y * sin_a),
                cy + int(x * sin_a + y * cos_a))

    # --- Blade (wide rectangular body, bottom half) ---
    bw = int(SIZE * 0.22)   # half-width of blade
    bh = int(SIZE * 0.32)   # half-height of blade
    boff = int(SIZE * 0.08) # vertical offset downward

    blade = [rot(-bw, boff - bh), rot(bw, boff - bh),
             rot(bw, boff + bh),  rot(-bw, boff + bh)]
    draw.polygon(blade, fill=bat_color)

    # Blade edge highlight
    edge_w = int(bw * 0.15)
    edge = [rot(bw - edge_w, boff - bh), rot(bw, boff - bh),
            rot(bw, boff + bh),          rot(bw - edge_w, boff + bh)]
    draw.polygon(edge, fill=grain_color)

    # Grain lines on blade
    for i in range(1, 8):
        t = i / 8
        x = -bw + int(2 * bw * t)
        p1, p2 = rot(x, boff - bh + 10), rot(x, boff + bh - 10)
        draw.line([p1, p2], fill=grain_color, width=max(2, int(SIZE * 0.004)))

    # --- Handle (thin rectangle, upper half) ---
    hw = int(bw * 0.22)
    hh = int(SIZE * 0.25)
    hoff = boff - bh  # connects at top of blade

    handle = [rot(-hw, hoff - hh), rot(hw, hoff - hh),
              rot(hw, hoff),        rot(-hw, hoff)]
    draw.polygon(handle, fill=handle_color)

    # Handle grip wrapping (diagonal lines)
    grip_color = (*[max(0, c - 40) for c in handle_color[:3]], 255)
    for i in range(0, hh, int(SIZE * 0.018)):
        p1 = rot(-hw, hoff - hh + i)
        p2 = rot(hw,  hoff - hh + i + int(hw * 0.6))
        draw.line([p1, p2], fill=grip_color, width=max(2, int(SIZE * 0.005)))

    # Grip top cap
    cap = [rot(-hw, hoff - hh), rot(hw, hoff - hh),
           rot(hw - int(hw * 0.3), hoff - hh - int(SIZE * 0.025)),
           rot(-hw + int(hw * 0.3), hoff - hh - int(SIZE * 0.025))]
    draw.polygon(cap, fill=grip_color)

    return img


# ── Icon Factory ───────────────────────────────────────────────────────────────

def make_icon(filename, top_bg, bot_bg, draw_fn, *fn_args):
    img = gradient_bg(SIZE, top_bg, bot_bg)
    img = draw_fn(img, *fn_args)
    img.save(filename, "PNG")
    print(f"  ✓  {filename}")


def ensure_appiconset(name):
    path = os.path.join(XCASSETS, f"{name}.appiconset")
    os.makedirs(path, exist_ok=True)
    return path


def write_contents(path, entries):
    import json
    data = {"images": entries, "info": {"author": "xcode", "version": 1}}
    with open(os.path.join(path, "Contents.json"), "w") as f:
        json.dump(data, f, indent=2)


# ── Generate ───────────────────────────────────────────────────────────────────

print("\n🏏  Generating CricPulse icons…\n")

os.makedirs("scripts", exist_ok=True)

CRICKET_RED   = (220, 31,  38)
WHITE         = (255, 248, 248)
DARK_BG_TOP   = (8,   8,  18)
DARK_BG_BOT   = (22,  8,  12)
RED_BG_TOP    = (140,  4,  8)
RED_BG_BOT    = (220, 31, 38)
GREEN_BG_TOP  = (4,  30,  6)
GREEN_BG_BOT  = (10, 55, 12)
CREAM_BG_TOP  = (245,235,210)
CREAM_BG_BOT  = (210,190,155)
WILLOW        = (210,175,115)
WILLOW_GRAIN  = (180,145, 88)
HANDLE_DARK   = (60,  35, 20)
HANDLE_MID    = (90,  60, 35)

icons = {
    # Ball icons
    "AppIconBall": {
        "bg": (RED_BG_TOP, RED_BG_BOT),
        "fn": draw_ball,
        "args": [WHITE, (180, 8, 12, 255)],
    },
    "AppIconBallDark": {
        "bg": (DARK_BG_TOP, DARK_BG_BOT),
        "fn": draw_ball,
        "args": [CRICKET_RED + (255,), (255, 255, 255, 200)],
    },
    # Bat icons
    "AppIconBat": {
        "bg": (GREEN_BG_TOP, GREEN_BG_BOT),
        "fn": draw_bat,
        "args": [WILLOW + (255,), WILLOW_GRAIN + (255,), HANDLE_DARK + (255,)],
    },
    "AppIconBatDark": {
        "bg": (DARK_BG_TOP, DARK_BG_BOT),
        "fn": draw_bat,
        "args": [WILLOW_GRAIN + (255,), CREAM_BG_BOT + (255,), HANDLE_MID + (255,)],
    },
}

for name, cfg in icons.items():
    folder = ensure_appiconset(name)
    png_path = os.path.join(folder, f"{name}.png")
    make_icon(png_path, *cfg["bg"], cfg["fn"], *cfg["args"])
    write_contents(folder, [
        {"filename": f"{name}.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}
    ])

# Update the primary AppIcon to use the ball (default)
primary = ensure_appiconset("AppIcon")
ball_src = os.path.join(XCASSETS, "AppIconBall.appiconset", "AppIconBall.png")
import shutil
shutil.copy(ball_src, os.path.join(primary, "AppIcon.png"))
write_contents(primary, [
    {"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
    {"appearances": [{"appearance": "luminosity", "value": "dark"}],
     "idiom": "universal", "platform": "ios", "size": "1024x1024"},
])

print("\n✅  Done. 4 icons generated in Assets.xcassets.\n")
print("Next step in Xcode:")
print("  Target → Build Settings → search 'Alternate App Icon Sets'")
print("  Add: AppIconBall AppIconBallDark AppIconBat AppIconBatDark\n")
