#!/usr/bin/env python3
"""
AgriDigitale — High-Conversion Video Ad (Téléchargement de l'Application)
Format: 1080x1920 (9:16 Vertical Reel/TikTok/Status/Ad)
Duration: 18.0s @ 30fps = 540 frames
Sound Design: 15-track multi-audio mix with synchronized SFX
"""

import os
import sys
import math
import time
import subprocess
from multiprocessing import Pool, cpu_count
from PIL import Image, ImageDraw, ImageFont, ImageFilter

WIDTH, HEIGHT = 1080, 1920
FPS = 30
DURATION_SEC = 18
TOTAL_FRAMES = FPS * DURATION_SEC

BASE_DIR = '/home/germain/Desktop/Programmation/agridigitale-mobile'
CAPTURES_DIR = os.path.join(BASE_DIR, 'Captures')
AUDIO_DIR = os.path.join(BASE_DIR, 'AgriDigitale/frontend/frontend/assets/sounds')
SFX_DIR = os.path.join(BASE_DIR, 'video-motion/sfx')
OUT_DIR = os.path.join(BASE_DIR, 'video-motion/output')
FRAMES_DIR = '/tmp/agridigitale_ad_frames'

FONT_BOLD = '/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf'
FONT_SEMI = '/usr/share/fonts/opentype/inter/Inter-SemiBold.otf'
FONT_REG  = '/usr/share/fonts/opentype/inter/Inter-Regular.otf'
LOGO_PATH = os.path.join(BASE_DIR, 'AgriDigitale', 'logo_officiel.png')

os.makedirs(FRAMES_DIR, exist_ok=True)
os.makedirs(OUT_DIR, exist_ok=True)

# Easing functions
def ease_out_back(t, c1=1.70158):
    c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)

def ease_out_cubic(t):
    return 1 - math.pow(1 - t, 3)

def ease_in_out_cubic(t):
    return 4 * t * t * t if t < 0.5 else 1 - math.pow(-2 * t + 2, 3) / 2

def clamp(v, mn=0.0, mx=1.0):
    return max(mn, min(mx, v))

# Pre-cropped screenshots
def load_and_prep_screenshots():
    def prep(name):
        path = os.path.join(CAPTURES_DIR, name)
        img = Image.open(path).convert('RGBA')
        return img.crop((0, 72, img.width, 1115))

    return {
        'accueil': prep('Accueil 1.jpg'),
        'accueil2': prep('Accueil 2.jpg'),
        'prix': prep('prix du marché.jpg'),
        'meteo': prep('Meteo 1.jpg'),
        'quizz': prep('jeux quizz 1.jpg'),
        'conseil': prep('conseil du jour 1.jpg'),
    }

SCREENSHOTS = load_and_prep_screenshots()
LOGO_IMG = Image.open(LOGO_PATH).convert('RGBA') if os.path.exists(LOGO_PATH) else None

# Helper: Device Frame (Phone Mockup)
def draw_phone_mockup(screen_img, target_w=580, target_h=1160, corner_r=46, shadow=True):
    total_w = target_w + 32
    total_h = target_h + 32
    device = Image.new('RGBA', (total_w, total_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(device)

    # Bezel
    d.rounded_rectangle([(16, 16), (total_w - 16, total_h - 16)], radius=corner_r + 8,
                        fill=(15, 23, 20, 255), outline=(52, 70, 60, 255), width=4)

    # Scaled screen
    screen_resized = screen_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    # Rounded mask for screen
    mask = Image.new('L', (target_w, target_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (target_w, target_h)], radius=corner_r, fill=255)
    
    device.paste(screen_resized, (16, 16), mask)

    # Speaker notch at top
    nw, nh = 130, 8
    nx = (total_w - nw) // 2
    d.rounded_rectangle([(nx, 26), (nx + nw, 26 + nh)], radius=4, fill=(35, 45, 40, 255))
    d.ellipse([(nx + nw + 14, 26), (nx + nw + 22, 34)], fill=(20, 30, 25, 255))

    return device

# Draw official Google Play Store badge
def draw_google_play_badge(width=440, height=114):
    badge = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(badge)
    
    # Outer container
    draw.rounded_rectangle([(2, 2), (width - 2, height - 2)], radius=24, fill=(15, 20, 24, 255),
                           outline=(50, 75, 60, 255), width=3)
    
    # Play icon
    ix, iy = 56, height // 2
    s = 30
    
    p_left_top = (ix - s * 0.55, iy - s)
    p_left_bot = (ix - s * 0.55, iy + s)
    p_right = (ix + s * 0.85, iy)
    p_center = (ix + s * 0.15, iy)
    
    draw.polygon([p_left_top, p_left_bot, p_center], fill=(0, 195, 255, 255))
    draw.polygon([p_left_top, p_center, p_right], fill=(0, 230, 118, 255))
    draw.polygon([p_left_bot, p_center, p_right], fill=(255, 213, 0, 255))
    draw.polygon([p_center, p_right, (ix + s * 0.4, iy - s * 0.3), (ix + s * 0.4, iy + s * 0.3)], fill=(255, 51, 75, 255))

    f_small = ImageFont.truetype(FONT_SEMI, 17)
    f_large = ImageFont.truetype(FONT_BOLD, 32)
    
    draw.text((112, 22), "DISPONIBLE SUR", font=f_small, fill=(170, 185, 200, 255))
    draw.text((112, 48), "Google Play", font=f_large, fill=(255, 255, 255, 255))
    
    return badge

PLAY_BADGE = draw_google_play_badge()

# Helper: Draw Floating Pill
def draw_pill(text, bg_color, border_color, text_color, font_size=28, height=64, px=32):
    font = ImageFont.truetype(FONT_BOLD, font_size)
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    w = tw + px * 2
    img = Image.new('RGBA', (w, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([(0, 0), (w, height)], radius=height // 2, fill=bg_color, outline=border_color, width=2)
    ty = (height - (bbox[3] - bbox[1])) // 2 - bbox[1]
    d.text((px, ty), text, font=font, fill=text_color)
    return img

# Helper: Draw Notification Floating Card
def draw_feature_card(title, subtitle, badge_txt, badge_color, width=720, height=136):
    card = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle([(0, 0), (width, height)], radius=24, fill=(18, 28, 22, 245),
                        outline=(45, 80, 55, 255), width=2)

    # Badge on right
    fb = ImageFont.truetype(FONT_BOLD, 22)
    bb = fb.getbbox(badge_txt)
    bw = bb[2] - bb[0] + 28
    bh = 38
    bx = width - bw - 24
    by = (height - bh) // 2
    d.rounded_rectangle([(bx, by), (bx + bw, by + bh)], radius=12, fill=badge_color)
    b_ty = by + (bh - (bb[3] - bb[1])) // 2 - bb[1]
    d.text((bx + 14, b_ty), badge_txt, font=fb, fill=(255, 255, 255, 255))

    # Text on left
    f_t = ImageFont.truetype(FONT_BOLD, 28)
    f_s = ImageFont.truetype(FONT_REG, 22)
    d.text((28, 28), title, font=f_t, fill=(255, 255, 255, 255))
    d.text((28, 76), subtitle, font=f_s, fill=(175, 210, 185, 255))
    return card

# Helper: Radial Gradient Background
def make_gradient_bg(c_top, c_mid, c_bot):
    bg = Image.new('RGBA', (WIDTH, HEIGHT))
    d = ImageDraw.Draw(bg)
    # Simple 3-step vertical interpolation
    for y in range(HEIGHT):
        ratio = y / HEIGHT
        if ratio < 0.5:
            r = int(c_top[0] + (c_mid[0] - c_top[0]) * (ratio * 2))
            g = int(c_top[1] + (c_mid[1] - c_top[1]) * (ratio * 2))
            b = int(c_top[2] + (c_mid[2] - c_top[2]) * (ratio * 2))
        else:
            sub = (ratio - 0.5) * 2
            r = int(c_mid[0] + (c_bot[0] - c_mid[0]) * sub)
            g = int(c_mid[1] + (c_bot[1] - c_mid[1]) * sub)
            b = int(c_mid[2] + (c_bot[2] - c_mid[2]) * sub)
        d.line([(0, y), (WIDTH, y)], fill=(r, g, b, 255))
    return bg

BG_ALERT   = make_gradient_bg((25, 12, 10), (18, 16, 20), (10, 12, 16))
BG_EMERALD = make_gradient_bg((6, 28, 18), (10, 42, 28), (8, 22, 16))
BG_BLUE    = make_gradient_bg((8, 22, 38), (12, 35, 55), (6, 18, 26))
BG_PURPLE  = make_gradient_bg((18, 14, 32), (25, 20, 48), (12, 10, 22))
BG_FINALE  = make_gradient_bg((4, 32, 20), (8, 56, 32), (6, 26, 18))


def render_ad_frame(frame_idx):
    t_sec = frame_idx / FPS

    # Canvas
    img = Image.new('RGBA', (WIDTH, HEIGHT))
    d = ImageDraw.Draw(img)

    # ==============================================================
    # SCENE 1: THE HOOK / AGITATION (0.0s - 3.5s | Frames 0 - 105)
    # "Marre de perdre de l'argent sur vos récoltes ?"
    # ==============================================================
    if t_sec < 3.5:
        p = t_sec / 3.5
        img.paste(BG_ALERT)

        # Danger pulse glow
        glow_alpha = int(45 + 30 * math.sin(t_sec * 8))
        d.ellipse([(WIDTH // 2 - 450, 400), (WIDTH // 2 + 450, 1300)],
                  fill=(180, 40, 20, glow_alpha))

        # Top Warning Badge
        b_p = clamp(t_sec / 0.5)
        b_y = int(-80 + ease_out_back(b_p) * 220)
        pill = draw_pill("ATTENTION PRODUCTEURS & COMMERÇANTS",
                         (80, 20, 20, 230), (220, 50, 50, 255), (255, 210, 210, 255),
                         font_size=24, height=56, px=28)
        img.paste(pill, ((WIDTH - pill.width) // 2, b_y), pill)

        # Headline
        t1_p = clamp((t_sec - 0.3) / 0.6)
        if t1_p > 0:
            scale_anim = ease_out_back(t1_p)
            f_huge = ImageFont.truetype(FONT_BOLD, 52)
            d.text((WIDTH // 2, 260), "Vous perdez encore", font=f_huge,
                   fill=(255, 255, 255, 255), anchor="mm")
            
            f_red = ImageFont.truetype(FONT_BOLD, 62)
            d.text((WIDTH // 2, 336), "DE L'ARGENT AUX RÉCOLTES ?", font=f_red,
                   fill=(255, 75, 75, 255), anchor="mm")

        # Central Visual: Agitated tilted phone with red error aura
        ph_p = clamp((t_sec - 0.8) / 0.6)
        if ph_p > 0:
            shake = math.sin(t_sec * 24) * 6 if t_sec < 2.2 else 0
            phone = draw_phone_mockup(SCREENSHOTS['prix'], target_w=520, target_h=1040)
            py = int(HEIGHT + 100 - ease_out_back(ph_p) * 1180)
            img.paste(phone, (int((WIDTH - phone.width) // 2 + shake), py), phone)

        # Problem tags popping up
        if t_sec > 1.2:
            tag1 = draw_pill("Intermédiaires abusifs", (180, 30, 30, 255), (255, 80, 80, 255), (255, 255, 255, 255), 24, 52, 24)
            img.paste(tag1, (80, 1180), tag1)
        if t_sec > 1.7:
            tag2 = draw_pill("Prix du marché inconnus", (180, 30, 30, 255), (255, 80, 80, 255), (255, 255, 255, 255), 24, 52, 24)
            img.paste(tag2, (WIDTH - tag2.width - 80, 1260), tag2)

        # Big Breakthrough Punch at 2.2s: "STOP AUX PERTES !"
        if t_sec > 2.2:
            st_p = clamp((t_sec - 2.2) / 0.4)
            st_scale = ease_out_back(st_p, c1=2.5)
            f_stop = ImageFont.truetype(FONT_BOLD, int(46 * st_scale))
            stop_box = draw_pill("STOP AUX PERTES AGRICOLES !", (220, 25, 25, 255), (255, 255, 255, 255), (255, 255, 255, 255), font_size=int(32 * st_scale), height=int(74 * st_scale), px=36)
            img.paste(stop_box, ((WIDTH - stop_box.width) // 2, 880), stop_box)

    # ==============================================================
    # SCENE 2: PRIX DU MARCHÉ EN TEMPS RÉEL (3.5s - 7.0s | Frames 105 - 210)
    # "Vendez toujours au prix fort !"
    # ==============================================================
    elif t_sec < 7.0:
        s_t = t_sec - 3.5
        p = s_t / 3.5
        img.paste(BG_EMERALD)

        # Radiant green ambient glow
        d.ellipse([(WIDTH // 2 - 400, 300), (WIDTH // 2 + 400, 1100)],
                  fill=(16, 185, 129, 35))

        # Top Pill
        pill = draw_pill("PRIX EN TEMPS RÉEL",
                         (10, 50, 30, 240), (16, 185, 129, 255), (52, 211, 153, 255),
                         font_size=24, height=56, px=28)
        b_p = clamp(s_t / 0.4)
        b_y = int(-60 + ease_out_back(b_p) * 200)
        img.paste(pill, ((WIDTH - pill.width) // 2, b_y), pill)

        # Headline
        f_h1 = ImageFont.truetype(FONT_BOLD, 54)
        f_h2 = ImageFont.truetype(FONT_BOLD, 44)
        d.text((WIDTH // 2, 235), "Ne vendez plus à l'aveugle", font=f_h1,
               fill=(255, 255, 255, 255), anchor="mm")
        d.text((WIDTH // 2, 295), "Comparez les marchés en direct !", font=f_h2,
               fill=(52, 211, 153, 255), anchor="mm")

        # Phone mockup zooming in
        ph_p = clamp(s_t / 0.6)
        scale_val = ease_out_cubic(ph_p)
        phone = draw_phone_mockup(SCREENSHOTS['prix'], target_w=540, target_h=1080)
        py = int(HEIGHT - scale_val * 1150)
        img.paste(phone, ((WIDTH - phone.width) // 2, py), phone)

        # Floating dynamic live price cards
        if s_t > 0.8:
            c1_p = clamp((s_t - 0.8) / 0.4)
            card1 = draw_feature_card("Maïs Blanc — Marché Central", "Lomé • Cours actualisé à 08h00", "+14% HAUSSE", (16, 185, 129, 255))
            c1_x = int(- card1.width + ease_out_back(c1_p) * (card1.width + (WIDTH - card1.width) // 2))
            img.paste(card1, (c1_x, 1160), card1)

        if s_t > 1.8:
            c2_p = clamp((s_t - 1.8) / 0.4)
            card2 = draw_feature_card("Soja Biologique", "Kara / Dapaong • Demande forte", "420 F/kg", (245, 158, 11, 255))
            c2_x = int(WIDTH - ease_out_back(c2_p) * (WIDTH - (WIDTH - card2.width) // 2))
            img.paste(card2, (c2_x, 1320), card2)

        # Footer badge
        if s_t > 2.2:
            tip = draw_pill("Maximisez vos bénéfices à chaque vente", (15, 30, 22, 220), (50, 100, 70, 255), (200, 240, 220, 255), 24, 52, 28)
            img.paste(tip, ((WIDTH - tip.width) // 2, 1490), tip)

    # ==============================================================
    # SCENE 3: MÉTÉO AGRICOLE 7 JOURS (7.0s - 10.5s | Frames 210 - 315)
    # "Anticipez la pluie avant de récolter !"
    # ==============================================================
    elif t_sec < 10.5:
        s_t = t_sec - 7.0
        p = s_t / 3.5
        img.paste(BG_BLUE)

        # Ambient cyan/blue glow
        d.ellipse([(WIDTH // 2 - 400, 300), (WIDTH // 2 + 400, 1100)],
                  fill=(14, 165, 233, 30))

        # Top Pill
        pill = draw_pill("MÉTÉO AGRICOLE GÉOLOCALISÉE",
                         (10, 35, 60, 240), (14, 165, 233, 255), (125, 211, 252, 255),
                         font_size=24, height=56, px=28)
        b_p = clamp(s_t / 0.4)
        b_y = int(-60 + ease_out_back(b_p) * 200)
        img.paste(pill, ((WIDTH - pill.width) // 2, b_y), pill)

        # Headline
        f_h1 = ImageFont.truetype(FONT_BOLD, 54)
        f_h2 = ImageFont.truetype(FONT_BOLD, 44)
        d.text((WIDTH // 2, 235), "Protégez vos récoltes", font=f_h1,
               fill=(255, 255, 255, 255), anchor="mm")
        d.text((WIDTH // 2, 295), "Prévisions & alertes pluie à 7 jours", font=f_h2,
               fill=(56, 189, 248, 255), anchor="mm")

        # Phone mockup showing meteo
        ph_p = clamp(s_t / 0.6)
        scale_val = ease_out_cubic(ph_p)
        phone = draw_phone_mockup(SCREENSHOTS['meteo'], target_w=540, target_h=1080)
        py = int(HEIGHT - scale_val * 1150)
        img.paste(phone, ((WIDTH - phone.width) // 2, py), phone)

        # Floating weather alert cards
        if s_t > 0.8:
            c1_p = clamp((s_t - 0.8) / 0.4)
            card1 = draw_feature_card("Alerte Pluies Fortes dans 48h", "Planifiez vos récoltes en sécurité", "RISQUE 85%", (239, 68, 68, 255))
            c1_y = int(HEIGHT - ease_out_back(c1_p) * 720)
            img.paste(card1, ((WIDTH - card1.width) // 2, c1_y), card1)

        if s_t > 1.8:
            c2_p = clamp((s_t - 1.8) / 0.4)
            card2 = draw_feature_card("Carte Interactive SVG", "Suivez la météo de toute votre région", "EN DIRECT", (14, 165, 233, 255))
            c2_y = int(HEIGHT - ease_out_back(c2_p) * 560)
            img.paste(card2, ((WIDTH - card2.width) // 2, c2_y), card2)

    # ==============================================================
    # SCENE 4: CONSEILS, QUIZ & RÉSEAU (10.5s - 14.0s | Frames 315 - 420)
    # "Boostez votre savoir & gagnez !"
    # ==============================================================
    elif t_sec < 14.0:
        s_t = t_sec - 10.5
        p = s_t / 3.5
        img.paste(BG_PURPLE)

        # Ambient violet/amber glow
        d.ellipse([(WIDTH // 2 - 400, 300), (WIDTH // 2 + 400, 1100)],
                  fill=(168, 85, 247, 30))

        # Top Pill
        pill = draw_pill("QUIZ, CONSEILS & AGRIDIGITALE TV",
                         (45, 25, 65, 240), (168, 85, 247, 255), (216, 180, 254, 255),
                         font_size=24, height=56, px=28)
        b_p = clamp(s_t / 0.4)
        b_y = int(-60 + ease_out_back(b_p) * 200)
        img.paste(pill, ((WIDTH - pill.width) // 2, b_y), pill)

        # Headline
        f_h1 = ImageFont.truetype(FONT_BOLD, 54)
        f_h2 = ImageFont.truetype(FONT_BOLD, 44)
        d.text((WIDTH // 2, 235), "Formations & Quiz 100% Gratuits", font=f_h1,
               fill=(255, 255, 255, 255), anchor="mm")
        d.text((WIDTH // 2, 295), "Gagnez des points & boostez vos récoltes !", font=f_h2,
               fill=(245, 158, 11, 255), anchor="mm")

        # Phone mockup showing quiz
        ph_p = clamp(s_t / 0.6)
        scale_val = ease_out_cubic(ph_p)
        phone = draw_phone_mockup(SCREENSHOTS['quizz'], target_w=540, target_h=1080)
        py = int(HEIGHT - scale_val * 1150)
        img.paste(phone, ((WIDTH - phone.width) // 2, py), phone)

        # Floating gamification badges
        if s_t > 0.9:
            c1_p = clamp((s_t - 0.9) / 0.4)
            card1 = draw_feature_card("Quiz Quotidien : Fertilité des sols", "Répondez et grimpez au classement !", "+150 XP", (234, 179, 8, 255))
            c1_x = int(- card1.width + ease_out_back(c1_p) * (card1.width + (WIDTH - card1.width) // 2))
            img.paste(card1, (c1_x, 1170), card1)

        if s_t > 1.9:
            c2_p = clamp((s_t - 1.9) / 0.4)
            card2 = draw_feature_card("Conseil du Jour par les Experts", "Fiches techniques claires et pratiques", "OFFERT", (34, 197, 94, 255))
            c2_x = int(WIDTH - ease_out_back(c2_p) * (WIDTH - (WIDTH - card2.width) // 2))
            img.paste(card2, (c2_x, 1330), card2)

    # ==============================================================
    # SCENE 5: THE IRRESISTIBLE DOWNLOAD CTA (14.0s - 18.0s | Frames 420 - 540)
    # "Téléchargez gratuitement l'application N°1"
    # ==============================================================
    else:
        s_t = t_sec - 14.0
        p = s_t / 4.0
        img.paste(BG_FINALE)

        # Radiant emerald & gold pulse
        pulse = 1.0 + 0.04 * math.sin(s_t * 6)
        d.ellipse([(WIDTH // 2 - 450, 200), (WIDTH // 2 + 450, 1100)],
                  fill=(16, 185, 129, 45))

        # Official Logo with entrance
        if LOGO_IMG:
            l_p = clamp(s_t / 0.5)
            l_scale = ease_out_back(l_p)
            logo_w = int(220 * l_scale)
            logo_h = int(LOGO_IMG.height * (logo_w / LOGO_IMG.width))
            if logo_w > 10:
                l_res = LOGO_IMG.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
                lx = (WIDTH - logo_w) // 2
                ly = int(120 + 20 * (1 - l_scale))
                img.paste(l_res, (lx, ly), l_res)

        # 5 Gold Stars Rating
        if s_t > 0.4:
            f_stars = ImageFont.truetype(FONT_BOLD, 36)
            f_rating = ImageFont.truetype(FONT_SEMI, 24)
            d.text((WIDTH // 2, 380), "★ ★ ★ ★ ★", font=f_stars, fill=(255, 215, 0, 255), anchor="mm")
            d.text((WIDTH // 2, 424), "NOTÉ 4.9/5 PAR DES MILLIERS DE PRODUCTEURS", font=f_rating,
                   fill=(180, 230, 200, 255), anchor="mm")

        # Huge Catchy Headline
        if s_t > 0.6:
            c_p = clamp((s_t - 0.6) / 0.4)
            f_h1 = ImageFont.truetype(FONT_BOLD, 56)
            f_h2 = ImageFont.truetype(FONT_BOLD, 46)
            d.text((WIDTH // 2, 510), "TÉLÉCHARGEZ MAINTENANT", font=f_h1,
                   fill=(255, 255, 255, 255), anchor="mm")
            d.text((WIDTH // 2, 580), "L'application agricole N°1 en Afrique !", font=f_h2,
                   fill=(52, 211, 153, 255), anchor="mm")

        # Showcase: Preview Phones in background
        if s_t > 0.8:
            phone_scale = 0.8
            p_w, p_h = int(520 * phone_scale), int(1040 * phone_scale)
            # Left phone
            ph_left = draw_phone_mockup(SCREENSHOTS['accueil'], target_w=p_w, target_h=p_h)
            img.paste(ph_left, (80, 880), ph_left)
            # Right phone
            ph_right = draw_phone_mockup(SCREENSHOTS['prix'], target_w=p_w, target_h=p_h)
            img.paste(ph_right, (WIDTH - ph_right.width - 80, 880), ph_right)

        # Google Play Badge
        if s_t > 1.0:
            gp_p = clamp((s_t - 1.0) / 0.4)
            gp_y = int(HEIGHT - ease_out_back(gp_p) * 440)
            img.paste(PLAY_BADGE, ((WIDTH - PLAY_BADGE.width) // 2, gp_y), PLAY_BADGE)

        # Pulsing CTA Button: "INSTALLER L'APPLICATION"
        if s_t > 1.3:
            btn_w = int(580 * pulse)
            btn_h = int(90 * pulse)
            btn = Image.new('RGBA', (btn_w, btn_h), (0, 0, 0, 0))
            bd = ImageDraw.Draw(btn)
            bd.rounded_rectangle([(0, 0), (btn_w, btn_h)], radius=btn_h // 2,
                                fill=(16, 185, 129, 255), outline=(167, 243, 208, 255), width=3)
            f_btn = ImageFont.truetype(FONT_BOLD, int(32 * pulse))
            bbox = f_btn.getbbox("INSTALLER L'APPLICATION")
            bw = bbox[2] - bbox[0]
            bh = bbox[3] - bbox[1]
            bd.text(((btn_w - bw) // 2, (btn_h - bh) // 2 - bbox[1]), "INSTALLER L'APPLICATION",
                    font=f_btn, fill=(255, 255, 255, 255))
            
            btn_x = (WIDTH - btn_w) // 2
            btn_y = 1600
            img.paste(btn, (btn_x, btn_y), btn)

        # Final Trust Tagline
        if s_t > 1.6:
            f_sub = ImageFont.truetype(FONT_SEMI, 24)
            d.text((WIDTH // 2, 1740), "100% Gratuit • Sans abonnement • Disponible hors ligne",
                   font=f_sub, fill=(160, 205, 185, 255), anchor="mm")
            
            f_net = ImageFont.truetype(FONT_BOLD, 22)
            d.text((WIDTH // 2, 1790), "www.agridigitale.net", font=f_net,
                   fill=(110, 160, 135, 255), anchor="mm")

    # Save frame
    out_path = os.path.join(FRAMES_DIR, f'frame_{frame_idx:04d}.jpg')
    img.convert('RGB').save(out_path, quality=92)


def main():
    t0 = time.time()
    print(f"Starting render of {TOTAL_FRAMES} frames ({DURATION_SEC}s @ {FPS}fps) for Video 2 (Ad Download)...")

    num_workers = max(1, cpu_count() - 1)
    with Pool(num_workers) as pool:
        pool.map(render_ad_frame, range(TOTAL_FRAMES))

    t1 = time.time()
    print(f"Rendered {TOTAL_FRAMES} frames in {t1 - t0:.1f}s ({(TOTAL_FRAMES / (t1 - t0)):.1f} fps)")

    # Sound design & Audio Mixing
    print("Encoding MP4 and mixing 15-track sound design...")
    out_mp4 = os.path.join(OUT_DIR, 'AgriDigitale_Telechargement_Ad.mp4')

    music = os.path.join(AUDIO_DIR, 'quiz_jungle_marimba_loop.mp3')
    boom_sfx = os.path.join(SFX_DIR, 'boom.wav')
    whoosh_sfx = os.path.join(SFX_DIR, 'whoosh.wav')
    pop_sfx = os.path.join(SFX_DIR, 'pop.wav')
    chime_sfx = os.path.join(SFX_DIR, 'chime.wav')
    coin_sfx = os.path.join(AUDIO_DIR, 'quiz_coin.wav')
    wrong_sfx = os.path.join(AUDIO_DIR, 'quiz_wrong.wav')
    correct_sfx = os.path.join(AUDIO_DIR, 'quiz_correct.wav')
    victory_sfx = os.path.join(AUDIO_DIR, 'quiz_victory.wav')

    # SFX cue mapping:
    # 0: video
    # 1: music
    # 2: boom at 0ms (hook impact)
    # 3: wrong_sfx at 900ms (buzzer for problem)
    # 4: boom at 2200ms (stop aux pertes)
    # 5: whoosh at 3500ms (scene 2 transition)
    # 6: coin at 4400ms (price card 1)
    # 7: coin at 5400ms (price card 2)
    # 8: whoosh at 7000ms (scene 3 transition)
    # 9: chime at 7800ms (weather alert)
    # 10: whoosh at 10500ms (scene 4 transition)
    # 11: correct at 11400ms (quiz bonus xp)
    # 12: whoosh at 14000ms (scene 5 finale)
    # 13: boom at 14200ms (finale boom)
    # 14: victory at 14500ms (cta fanfare)
    # 15: chime at 15500ms (download badge chime)

    filter_complex = (
        "[1:a]afade=t=in:ss=0:d=0.4,afade=t=out:st=16.8:d=1.2,volume=0.38[a_music];"
        "[2:a]adelay=0|0,volume=1.4[s0];"
        "[3:a]adelay=900|900,volume=1.5[s1];"
        "[4:a]adelay=2200|2200,volume=1.3[s2];"
        "[5:a]adelay=3500|3500,volume=1.2[s3];"
        "[6:a]adelay=4400|4400,volume=1.5[s4];"
        "[7:a]adelay=5400|5400,volume=1.5[s5];"
        "[8:a]adelay=7000|7000,volume=1.2[s6];"
        "[9:a]adelay=7800|7800,volume=1.1[s7];"
        "[10:a]adelay=10500|10500,volume=1.2[s8];"
        "[11:a]adelay=11400|11400,volume=1.4[s9];"
        "[12:a]adelay=14000|14000,volume=1.3[s10];"
        "[13:a]adelay=14200|14200,volume=1.4[s11];"
        "[14:a]adelay=14500|14500,volume=1.5[s12];"
        "[15:a]adelay=15500|15500,volume=1.2[s13];"
        "[a_music][s0][s1][s2][s3][s4][s5][s6][s7][s8][s9][s10][s11][s12][s13]amix=inputs=15:duration=first:dropout_transition=2[a_out]"
    )

    cmd = [
        'ffmpeg', '-y',
        '-framerate', str(FPS),
        '-i', os.path.join(FRAMES_DIR, 'frame_%04d.jpg'),
        '-i', music,
        '-i', boom_sfx,
        '-i', wrong_sfx,
        '-i', boom_sfx,
        '-i', whoosh_sfx,
        '-i', coin_sfx,
        '-i', coin_sfx,
        '-i', whoosh_sfx,
        '-i', chime_sfx,
        '-i', whoosh_sfx,
        '-i', correct_sfx,
        '-i', whoosh_sfx,
        '-i', boom_sfx,
        '-i', victory_sfx,
        '-i', chime_sfx,
        '-filter_complex', filter_complex,
        '-map', '0:v',
        '-map', '[a_out]',
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '19',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-b:a', '192k',
        '-t', str(DURATION_SEC),
        out_mp4
    ]

    subprocess.run(cmd, check=True)
    t2 = time.time()
    print(f"SUCCESS! Video Ad rendered at: {out_mp4} (Total processing time: {t2 - t0:.1f}s)")

if __name__ == '__main__':
    main()
