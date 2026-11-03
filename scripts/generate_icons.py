#!/usr/bin/env python3
"""
Generate app icons for DaemonStraight
Vibrant, modern design with neon gradients
"""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

def create_radial_gradient(size, color1, color2):
    """Create a radial gradient"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center_x = size / 2
    center_y = size / 2
    max_radius = math.sqrt(center_x**2 + center_y**2)

    for i in range(size):
        for j in range(size):
            dx = i - center_x
            dy = j - center_y
            distance = math.sqrt(dx**2 + dy**2)
            ratio = min(distance / max_radius, 1.0)

            r = int(color1[0] + (color2[0] - color1[0]) * ratio)
            g = int(color1[1] + (color2[1] - color1[1]) * ratio)
            b = int(color1[2] + (color2[2] - color1[2]) * ratio)
            a = int(color1[3] + (color2[3] - color1[3]) * ratio)

            img.putpixel((i, j), (r, g, b, a))

    return img

def create_icon(size):
    """Create a vibrant icon with neon gradients"""
    # Create base image
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    padding = size * 0.08
    inner_size = size - (padding * 2)
    center_x = size / 2
    center_y = size / 2

    # Create vibrant gradient background (purple to blue to pink)
    base_rect = [padding, padding, size - padding, size - padding]
    corner_radius = max(2, inner_size * 0.22)

    # Multi-color gradient background
    for i in range(int(padding), int(size - padding)):
        ratio = (i - padding) / inner_size

        # Purple -> Blue -> Pink gradient
        if ratio < 0.5:
            # Purple to Blue
            t = ratio * 2
            r = int(120 + (80 - 120) * t)
            g = int(60 + (140 - 60) * t)
            b = int(220 + (255 - 220) * t)
        else:
            # Blue to Pink
            t = (ratio - 0.5) * 2
            r = int(80 + (255 - 80) * t)
            g = int(140 + (100 - 140) * t)
            b = int(255 + (200 - 255) * t)

        draw.rectangle([padding, i, size - padding, i + 1], fill=(r, g, b, 255))

    # Apply rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(base_rect, radius=corner_radius, fill=255)

    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(img, (0, 0), mask)
    img = output
    draw = ImageDraw.Draw(img)

    # Create presentation screen with neon effects
    screen_width = inner_size * 0.6
    screen_height = inner_size * 0.5
    screen_x = center_x - screen_width / 2
    screen_y = center_y - screen_height / 2

    # Draw glowing screen
    screen_rect = [screen_x, screen_y, screen_x + screen_width, screen_y + screen_height]
    screen_corner = max(2, screen_width * 0.15)

    # Screen with white glow
    glow_layers = 3
    for i in range(glow_layers, 0, -1):
        glow_size = i * 3
        glow_alpha = int(60 / i)
        glow_rect = [screen_rect[0] - glow_size, screen_rect[1] - glow_size,
                     screen_rect[2] + glow_size, screen_rect[3] + glow_size]
        draw.rounded_rectangle(glow_rect, radius=screen_corner + glow_size,
                              fill=(255, 255, 255, glow_alpha))

    # Main screen
    draw.rounded_rectangle(screen_rect, radius=screen_corner,
                          fill=(255, 255, 255, 240))

    # Draw feature symbols inside screen with neon colors
    symbol_size = inner_size * 0.08
    symbol_y = screen_y + screen_height * 0.35
    line_width = max(2, int(symbol_size * 0.3))

    # 1. Mouse circle (left) - Cyan neon
    mouse_x = screen_x + screen_width * 0.25
    mouse_r = symbol_size * 0.4
    draw.ellipse([mouse_x - mouse_r, symbol_y - mouse_r,
                  mouse_x + mouse_r, symbol_y + mouse_r],
                 outline=(0, 255, 255, 255), width=line_width)
    draw.ellipse([mouse_x - mouse_r * 0.3, symbol_y - mouse_r * 0.3,
                  mouse_x + mouse_r * 0.3, symbol_y + mouse_r * 0.3],
                 fill=(0, 255, 255, 255))

    # 2. Keyboard key (center) - Magenta neon
    key_x = screen_x + screen_width * 0.5
    key_size = symbol_size * 0.7
    key_rect = [key_x - key_size/2, symbol_y - key_size/2,
                key_x + key_size/2, symbol_y + key_size/2]
    draw.rounded_rectangle(key_rect, radius=max(1, key_size * 0.2),
                          outline=(255, 0, 200, 255), width=line_width)

    # 3. Drawing stroke (right) - Yellow-green neon
    stroke_x = screen_x + screen_width * 0.75
    stroke_points = []
    for i in range(6):
        t = i / 5
        x = stroke_x - symbol_size * 0.3 + t * symbol_size * 0.6
        y = symbol_y + math.sin(t * math.pi) * symbol_size * 0.3
        stroke_points.append((x, y))
    draw.line(stroke_points, fill=(150, 255, 100, 255), width=line_width, joint="curve")

    # Add subtle sparkle effect at top corners
    sparkle_size = inner_size * 0.06
    sparkle_positions = [
        (padding + inner_size * 0.2, padding + inner_size * 0.2),
        (size - padding - inner_size * 0.2, padding + inner_size * 0.2),
    ]

    for sx, sy in sparkle_positions:
        # Draw star-like sparkle
        sparkle_r = sparkle_size / 2
        sparkle_points = []
        for i in range(8):
            angle = i * math.pi / 4
            r = sparkle_r if i % 2 == 0 else sparkle_r * 0.4
            x = sx + r * math.cos(angle)
            y = sy + r * math.sin(angle)
            sparkle_points.append((x, y))
        draw.polygon(sparkle_points, fill=(255, 255, 255, 180))

    # Add highlight gradient on top
    highlight_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight_layer)

    for i in range(int(padding), int(padding + inner_size * 0.35)):
        ratio = (i - padding) / (inner_size * 0.35)
        alpha = int(40 * (1 - ratio))
        highlight_draw.rectangle([padding, i, size - padding, i + 1],
                                fill=(255, 255, 255, alpha))

    # Apply highlight mask
    highlight_mask = Image.new('L', (size, size), 0)
    highlight_mask_draw = ImageDraw.Draw(highlight_mask)
    highlight_mask_draw.rounded_rectangle(base_rect, radius=corner_radius, fill=255)

    highlight_layer.putalpha(highlight_mask)
    img = Image.alpha_composite(img, highlight_layer)

    # Add subtle border
    draw = ImageDraw.Draw(img)
    border_width = max(1, size // 100)
    draw.rounded_rectangle(base_rect, radius=corner_radius,
                          outline=(255, 255, 255, 100), width=border_width)

    # Add depth with shadow
    shadow = Image.new('RGBA', (size + 20, size + 20), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle([10, 12, size + 10, size + 12],
                                  radius=corner_radius, fill=(0, 0, 0, 100))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=8))

    final = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final.paste(shadow.crop((10, 10, size + 10, size + 10)), (0, 0))
    final = Image.alpha_composite(final, img)

    return final

def create_menubar_icon(size, is_template=False):
    """Create colorful menu bar icon with vibrant neon colors"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Use vibrant gradient colors for menu bar icon
    # Purple to blue gradient for the icon itself
    color = (120, 100, 255, 255)  # Vibrant purple-blue

    padding = size * 0.1
    inner_size = size - (padding * 2)
    center_x = size / 2
    center_y = size / 2

    line_width = max(1, size // 9)

    # Simple presentation screen
    screen_width = inner_size * 0.75
    screen_height = inner_size * 0.55
    screen_left = center_x - screen_width / 2
    screen_top = center_y - screen_height / 2 + padding * 0.3

    screen_rect = [screen_left, screen_top,
                   screen_left + screen_width, screen_top + screen_height]
    corner_r = max(1, inner_size * 0.15)

    # Rounded rectangle screen with gradient effect
    draw.rounded_rectangle(screen_rect, radius=corner_r,
                          outline=color, width=line_width)

    # Three feature dots inside with different vibrant colors
    dot_radius = max(1.5, size // 14)
    dot_y = screen_top + screen_height * 0.55
    dot_spacing = screen_width * 0.22

    dot_colors = [
        (0, 255, 255, 255),    # Cyan (mouse)
        (255, 0, 200, 255),    # Magenta (keyboard)
        (150, 255, 100, 255)   # Yellow-green (drawing)
    ]

    for i in range(3):
        dot_x = center_x - dot_spacing + (i * dot_spacing)
        draw.ellipse([dot_x - dot_radius, dot_y - dot_radius,
                      dot_x + dot_radius, dot_y + dot_radius],
                     fill=dot_colors[i])

    # Add a small wave/signal icon at top in gradient color
    wave_y = screen_top + screen_height * 0.25
    wave_points = []
    for i in range(5):
        t = i / 4
        x = center_x - screen_width * 0.25 + t * screen_width * 0.5
        y = wave_y + math.sin(t * math.pi * 2) * screen_height * 0.08
        wave_points.append((x, y))
    draw.line(wave_points, fill=(255, 180, 100, 255), width=line_width // 2 + 1, joint="curve")

    return img

def main():
    """Generate all icon sizes"""
    output_dir = "DaemonStraight/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    print("🎨 Generating DaemonStraight app icons (vibrant neon design)...")

    for size, filename in sizes:
        print(f"  Creating {filename} ({size}x{size})...")
        icon = create_icon(size)
        icon.save(os.path.join(output_dir, filename), "PNG")

    contents = {
        "images": [
            {"filename": "icon_16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16"},
            {"filename": "icon_16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16"},
            {"filename": "icon_32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32"},
            {"filename": "icon_32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32"},
            {"filename": "icon_128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128"},
            {"filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128"},
            {"filename": "icon_256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256"},
            {"filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256"},
            {"filename": "icon_512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512"},
            {"filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512"}
        ],
        "info": {"author": "xcode", "version": 1}
    }

    import json
    with open(os.path.join(output_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

    # Generate menu bar icons
    menubar_dir = "DaemonStraight/Assets.xcassets"
    menubar_iconset = os.path.join(menubar_dir, "MenuBarIcon.imageset")
    os.makedirs(menubar_iconset, exist_ok=True)

    print("\n🔧 Generating menu bar icons (COLORFUL - not template)...")

    menubar_icon_1x = create_menubar_icon(22, is_template=False)
    menubar_icon_2x = create_menubar_icon(44, is_template=False)
    menubar_icon_3x = create_menubar_icon(66, is_template=False)

    menubar_icon_1x.save(os.path.join(menubar_iconset, "menubar_icon.png"), "PNG")
    menubar_icon_2x.save(os.path.join(menubar_iconset, "menubar_icon@2x.png"), "PNG")
    menubar_icon_3x.save(os.path.join(menubar_iconset, "menubar_icon@3x.png"), "PNG")

    menubar_contents = {
        "images": [
            {"filename": "menubar_icon.png", "idiom": "universal", "scale": "1x"},
            {"filename": "menubar_icon@2x.png", "idiom": "universal", "scale": "2x"},
            {"filename": "menubar_icon@3x.png", "idiom": "universal", "scale": "3x"}
        ],
        "info": {"author": "xcode", "version": 1}
    }

    with open(os.path.join(menubar_iconset, "Contents.json"), "w") as f:
        json.dump(menubar_contents, f, indent=2)

    print("\n✅ Icon generation complete!")
    print(f"   App icons: {output_dir}")
    print(f"   Menu bar icon: {menubar_iconset}")
    print("\n💡 New design:")
    print("   - Vibrant purple-blue-pink gradient background")
    print("   - Glowing presentation screen in center")
    print("   - Three neon symbols (cyan, magenta, yellow-green)")
    print("   - Sparkle effects for extra flair")
    print("   - Menu bar icon with wave/signal graphic")

if __name__ == "__main__":
    main()
