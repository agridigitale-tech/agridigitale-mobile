import os
from PIL import Image, ImageDraw, ImageFont

FONT_BOLD = '/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf'
FONT_SEMI = '/usr/share/fonts/opentype/inter/Inter-SemiBold.otf'
FONT_REG  = '/usr/share/fonts/opentype/inter/Inter-Regular.otf'

def draw_google_play_badge(width=420, height=110):
    badge = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(badge)
    
    # Rounded black pill border
    draw.rounded_rectangle([(2, 2), (width - 2, height - 2)], radius=24, fill=(18, 20, 24, 255), outline=(60, 68, 78, 255), width=2)
    
    # Play icon inside (4-color google play triangle)
    # Centered vertically around x=55
    ix, iy = 52, height // 2
    s = 28 # size
    
    # Points of main triangle: (ix - s*0.6, iy - s), (ix - s*0.6, iy + s), (ix + s, iy)
    p_left_top = (ix - s*0.55, iy - s)
    p_left_bot = (ix - s*0.55, iy + s)
    p_right = (ix + s*0.85, iy)
    p_center = (ix + s*0.15, iy)
    
    # 4 distinct Google Play color polygons:
    # 1. Blue body: left edge to center
    draw.polygon([p_left_top, p_left_bot, p_center], fill=(0, 195, 255, 255))
    # 2. Green top triangle:
    draw.polygon([p_left_top, p_center, p_right], fill=(0, 230, 118, 255))
    # 3. Yellow/Orange bottom triangle:
    draw.polygon([p_left_bot, p_center, p_right], fill=(255, 213, 0, 255))
    # 4. Red right triangle:
    p_mid_top = ((p_left_top[0] + p_right[0]) / 2, (p_left_top[1] + p_right[1]) / 2)
    p_mid_bot = ((p_left_bot[0] + p_right[0]) / 2, (p_left_bot[1] + p_right[1]) / 2)
    draw.polygon([p_center, p_right, (ix + s*0.4, iy - s*0.3), (ix + s*0.4, iy + s*0.3)], fill=(255, 51, 75, 255))

    # Text: "DISPONIBLE SUR" (small) and "Google Play" (large)
    f_small = ImageFont.truetype(FONT_SEMI, 16)
    f_large = ImageFont.truetype(FONT_BOLD, 30)
    
    draw.text((105, 24), "DISPONIBLE SUR", font=f_small, fill=(180, 190, 205, 255))
    draw.text((105, 48), "Google Play", font=f_large, fill=(255, 255, 255, 255))
    
    return badge

if __name__ == '__main__':
    img = draw_google_play_badge()
    os.makedirs('/tmp/test_out', exist_ok=True)
    img.save('/tmp/test_out/play_badge.png')
    print("Badge saved at /tmp/test_out/play_badge.png")
