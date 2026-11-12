import os
import sys
import math
import time
import subprocess
from concurrent.futures import ProcessPoolExecutor
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

# Config
W, H = 1080, 1920
FPS = 30
DURATION_SEC = 28
TOTAL_FRAMES = FPS * DURATION_SEC

BASE_DIR = '/home/germain/Desktop/Programmation/agridigitale-mobile'
CAPTURES_DIR = os.path.join(BASE_DIR, 'Captures')
SFX_DIR = os.path.join(BASE_DIR, 'video-motion', 'sfx')
OUT_DIR = os.path.join(BASE_DIR, 'video-motion', 'output')
FRAMES_DIR = '/tmp/agridigitale_frames'

FONT_BOLD = '/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf'
FONT_SEMI = '/usr/share/fonts/opentype/inter/Inter-SemiBold.otf'
FONT_REG  = '/usr/share/fonts/opentype/inter/Inter-Regular.otf'
LOGO_PATH = os.path.join(BASE_DIR, 'AgriDigitale', 'logo_officiel.png')

os.makedirs(FRAMES_DIR, exist_ok=True)
os.makedirs(OUT_DIR, exist_ok=True)

# Helper: ease functions
def ease_out_back(t, c1=1.70158):
    c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)

def ease_out_cubic(t):
    return 1 - math.pow(1 - t, 3)

def ease_in_out_cubic(t):
    return 4 * t * t * t if t < 0.5 else 1 - math.pow(-2 * t + 2, 3) / 2

def clamp(v, mn=0.0, mx=1.0):
    return max(mn, min(mx, v))

# Pre-load and prepare cropped clean screenshots
def load_and_prep_screenshots():
    def prep(img_name):
        path = os.path.join(CAPTURES_DIR, img_name)
        img = Image.open(path).convert('RGBA')
        # Crop top status bar (72px) and bottom admin bar (starting around 1115px)
        return img.crop((0, 72, img.width, 1115))

    return {
        'accueil': prep('Accueil 1.jpg'),
        'meteo': prep('Meteo 1.jpg'),
        'prix': prep('prix du marché.jpg'),
        'conseil': prep('conseil du jour 1.jpg'),
        'quiz': prep('jeux quizz 1.jpg'),
    }

# Render a single frame
def render_frame_worker(f_idx, screens_data, logo_data):
    t_sec = f_idx / FPS

    # 1. Base Background
    frame = Image.new('RGBA', (W, H), (8, 28, 14, 255))
    draw = ImageDraw.Draw(frame)

    # Ambient deep green gradient
    for y in range(0, H, 2):
        factor = y / H
        r = int(10 * (1 - factor) + 4 * factor)
        g = int(42 * (1 - factor) + 16 * factor)
        b = int(20 * (1 - factor) + 8 * factor)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255), width=2)

    # Animated subtle ambient pulsing glow
    pulse = 0.5 + 0.5 * math.sin(f_idx * 0.08)
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    center_y = int(950 + 80 * math.sin(f_idx * 0.05))
    for rad in range(560, 40, -40):
        a = int((38 + 12 * pulse) * (1 - rad / 560))
        gdraw.ellipse([W//2 - rad, center_y - rad, W//2 + rad, center_y + rad], fill=(46, 160, 75, a))
    frame = Image.alpha_composite(frame, glow)

    # Ambient particles floating upwards
    np.random.seed(42)
    p_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(p_layer)
    for p_i in range(25):
        base_x = int(np.random.uniform(50, W - 50))
        base_y = int(np.random.uniform(0, H))
        speed = np.random.uniform(1.5, 3.5)
        rad_p = np.random.uniform(2, 5)
        cur_y = int((base_y - f_idx * speed) % H)
        cur_x = int(base_x + 18 * math.sin((f_idx + p_i * 10) * 0.04))
        p_alpha = int(90 * (1 - abs(cur_y - H/2) / (H/2)))
        pdraw.ellipse([cur_x - rad_p, cur_y - rad_p, cur_x + rad_p, cur_y + rad_p], fill=(160, 240, 180, max(0, p_alpha)))
    frame = Image.alpha_composite(frame, p_layer)

    # 2. Scene Logic based on frame index
    # S1: [0, 135] (0 - 4.5s) Intro Logo & Hook
    # S2: [135, 285] (4.5 - 9.5s) Météo Agricole
    # S3: [285, 435] (9.5 - 14.5s) Prix des Marchés
    # S4: [435, 585] (14.5 - 19.5s) Conseils du Jour
    # S5: [585, 720] (19.5 - 24.0s) Mode Hors-Ligne
    # S6: [720, 840] (24.0 - 28.0s) Call To Action Final

    f_bold_badge = ImageFont.truetype(FONT_BOLD, 26)
    f_bold_title = ImageFont.truetype(FONT_BOLD, 58)
    f_semi_sub   = ImageFont.truetype(FONT_SEMI, 32)
    f_bold_cta   = ImageFont.truetype(FONT_BOLD, 36)

    def draw_phone(screenshot, phone_x, phone_y, scale=1.0, alpha=1.0):
        if alpha <= 0.001: return
        phone_w = int(660 * scale)
        phone_h = int(1380 * scale)
        corner_r = int(54 * scale)
        screen_pad = int(14 * scale)

        p_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        pdraw = ImageDraw.Draw(p_layer)

        # Phone shadow
        shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(shadow)
        sdraw.rounded_rectangle(
            [phone_x - 12, phone_y + 20, phone_x + phone_w + 12, phone_y + phone_h + 40],
            radius=corner_r + 8,
            fill=(0, 0, 0, int(150 * alpha))
        )
        shadow = shadow.filter(ImageFilter.GaussianBlur(int(36 * scale)))
        nonlocal frame
        frame = Image.alpha_composite(frame, shadow)

        # Phone outer chassis
        pdraw.rounded_rectangle(
            [phone_x, phone_y, phone_x + phone_w, phone_y + phone_h],
            radius=corner_r,
            fill=(26, 30, 28, int(255 * alpha)),
            outline=(80, 105, 90, int(255 * alpha)),
            width=max(2, int(3 * scale))
        )

        # Screen inside
        screen_w = phone_w - 2 * screen_pad
        screen_h = phone_h - 2 * screen_pad
        screen_x = phone_x + screen_pad
        screen_y = phone_y + screen_pad

        ss_resized = screenshot.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
        mask = Image.new('L', (screen_w, screen_h), 0)
        mdraw = ImageDraw.Draw(mask)
        mdraw.rounded_rectangle([0, 0, screen_w, screen_h], radius=corner_r - screen_pad, fill=int(255 * alpha))

        p_layer.paste(ss_resized, (screen_x, screen_y), mask)

        # Dynamic Island Pill
        pill_w = int(130 * scale)
        pill_h = int(32 * scale)
        pill_x = phone_x + (phone_w - pill_w) // 2
        pill_y = screen_y + int(10 * scale)
        pdraw.rounded_rectangle([pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=pill_h//2, fill=(0, 0, 0, int(255 * alpha)))
        pdraw.ellipse([pill_x + pill_w - int(24 * scale), pill_y + int(8 * scale), pill_x + pill_w - int(10 * scale), pill_y + int(22 * scale)], fill=(20, 25, 35, int(255 * alpha)))

        frame = Image.alpha_composite(frame, p_layer)

    def draw_badge(badge_text, y_pos, bg_color=(255, 255, 255, 30), border_color=(76, 175, 80, 220), text_color=(165, 214, 167, 255), alpha=1.0):
        if alpha <= 0.01: return
        tdraw = ImageDraw.Draw(frame)
        bbox = f_bold_badge.getbbox(badge_text)
        bw = bbox[2] - bbox[0] + 44
        bh = 50
        bx = (W - bw) // 2
        tdraw.rounded_rectangle(
            [bx, y_pos, bx + bw, y_pos + bh],
            radius=25,
            fill=(bg_color[0], bg_color[1], bg_color[2], int(bg_color[3] * alpha)),
            outline=(border_color[0], border_color[1], border_color[2], int(border_color[3] * alpha)),
            width=2
        )
        tdraw.text((bx + 22, y_pos + 10), badge_text, font=f_bold_badge, fill=(text_color[0], text_color[1], text_color[2], int(text_color[3] * alpha)))

    def draw_titles(title, subtitle, y_title=220, y_sub=305, alpha=1.0):
        if alpha <= 0.01: return
        tdraw = ImageDraw.Draw(frame)
        tbox = f_bold_title.getbbox(title)
        tx = (W - (tbox[2] - tbox[0])) // 2
        tdraw.text((tx, y_title), title, font=f_bold_title, fill=(255, 255, 255, int(255 * alpha)))

        sbox = f_semi_sub.getbbox(subtitle)
        sx = (W - (sbox[2] - sbox[0])) // 2
        tdraw.text((sx, y_sub), subtitle, font=f_semi_sub, fill=(200, 230, 201, int(230 * alpha)))

    def draw_floating_card(title_card, subtitle_card, tag_text, tag_color, y_card=1400, alpha=1.0, scale=1.0):
        if alpha <= 0.01: return
        nonlocal frame
        pop_w = int(520 * scale)
        pop_h = int(144 * scale)
        pop_x = (W - pop_w) // 2
        pop_y = int(y_card)

        pop_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        pdraw = ImageDraw.Draw(pop_layer)
        # Shadow
        pdraw.rounded_rectangle([pop_x - 6, pop_y + 12, pop_x + pop_w + 6, pop_y + pop_h + 24], radius=int(26*scale), fill=(0, 0, 0, int(180 * alpha)))
        pop_layer = pop_layer.filter(ImageFilter.GaussianBlur(int(24 * scale)))

        pdraw2 = ImageDraw.Draw(pop_layer)
        pdraw2.rounded_rectangle([pop_x, pop_y, pop_x + pop_w, pop_y + pop_h], radius=int(24*scale), fill=(16, 48, 25, int(245 * alpha)), outline=(76, 175, 80, int(255 * alpha)), width=3)

        f_pop_t = ImageFont.truetype(FONT_BOLD, int(34 * scale))
        f_pop_s = ImageFont.truetype(FONT_SEMI, int(24 * scale))
        f_pop_b = ImageFont.truetype(FONT_BOLD, int(22 * scale))

        pdraw2.text((pop_x + int(26 * scale), pop_y + int(24 * scale)), title_card, font=f_pop_t, fill=(255, 255, 255, int(255 * alpha)))
        pdraw2.text((pop_x + int(26 * scale), pop_y + int(80 * scale)), subtitle_card, font=f_pop_s, fill=(165, 214, 167, int(255 * alpha)))

        # Tag
        tb_box = f_pop_b.getbbox(tag_text)
        tb_w = tb_box[2] - tb_box[0] + int(28 * scale)
        tb_h = int(48 * scale)
        tb_x = pop_x + pop_w - tb_w - int(24 * scale)
        tb_y = pop_y + int(48 * scale)
        pdraw2.rounded_rectangle([tb_x, tb_y, tb_x + tb_w, tb_y + tb_h], radius=tb_h//2, fill=(tag_color[0], tag_color[1], tag_color[2], int(255 * alpha)))
        pdraw2.text((tb_x + int(14 * scale), tb_y + int(10 * scale)), tag_text, font=f_pop_b, fill=(255, 255, 255, int(255 * alpha)))

        frame = Image.alpha_composite(frame, pop_layer)

    # ──────────────────────────────────────────────────────────
    # SCENE 1: Intro (Frames 0 - 135)
    # ──────────────────────────────────────────────────────────
    if f_idx < 135:
        p_in = clamp(f_idx / 35)
        scale_logo = 0.4 + 0.6 * ease_out_back(p_in)
        alpha_logo = clamp(f_idx / 25)

        # Draw Badge
        draw_badge('AGRICULTURE DIGITALE EN AFRIQUE', 400, alpha=clamp((f_idx - 15)/25))

        # Logo
        logo = logo_data
        lw = int(logo.width * 0.36 * scale_logo)
        lh = int(logo.height * 0.36 * scale_logo)
        if lw > 0 and lh > 0:
            logo_scaled = logo.resize((lw, lh), Image.Resampling.LANCZOS)
            lx = (W - lw) // 2
            ly = int(540 - 30 * (1 - ease_out_back(p_in)))

            # Logo Glow
            lglow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            lgdraw = ImageDraw.Draw(lglow)
            lgdraw.ellipse([lx - 30, ly - 30, lx + lw + 30, ly + lh + 30], fill=(76, 175, 80, int(60 * alpha_logo)))
            lglow = lglow.filter(ImageFilter.GaussianBlur(30))
            frame = Image.alpha_composite(frame, lglow)

            logo_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            logo_layer.paste(logo_scaled, (lx, ly), logo_scaled)
            frame = Image.alpha_composite(frame, logo_layer)

        # Title
        f_intro_t = ImageFont.truetype(FONT_BOLD, 74)
        t_alpha = clamp((f_idx - 30) / 25)
        it_box = f_intro_t.getbbox('AgriDigitale')
        it_x = (W - (it_box[2] - it_box[0])) // 2
        idraw = ImageDraw.Draw(frame)
        idraw.text((it_x, 930), 'AgriDigitale', font=f_intro_t, fill=(255, 255, 255, int(255 * t_alpha)))

        # Subtitle
        f_intro_s = ImageFont.truetype(FONT_SEMI, 36)
        s_alpha = clamp((f_idx - 45) / 25)
        is_box = f_intro_s.getbbox('L’intelligence agricole dans votre poche.')
        is_x = (W - (is_box[2] - is_box[0])) // 2
        idraw.text((is_x, 1035), 'L’intelligence agricole dans votre poche.', font=f_intro_s, fill=(165, 214, 167, int(240 * s_alpha)))

        # Feature pills at bottom
        f_alpha = clamp((f_idx - 65) / 25)
        draw_badge('Météo  •  Prix Marchés  •  Conseils  •  Hors-ligne', 1150, bg_color=(255,255,255,20), border_color=(46,125,50,180), text_color=(200,230,201,240), alpha=f_alpha)

    # ──────────────────────────────────────────────────────────
    # SCENE 2: Météo Agricole (Frames 135 - 285)
    # ──────────────────────────────────────────────────────────
    elif f_idx < 285:
        p_rel = (f_idx - 135)
        enter = clamp(p_rel / 30)
        eased = ease_out_back(enter)
        phone_y = int(1950 - 1470 * eased) # Arrives at y=480

        draw_badge('METEO AGRICOLE PREVISIONNELLE', 150, alpha=clamp(p_rel / 20))
        draw_titles('Ne subissez plus la météo.', 'Anticipez pluie et vent pour vos récoltes', y_title=230, y_sub=315, alpha=clamp(p_rel / 25))

        draw_phone(screens_data['meteo'], (W - 660)//2, phone_y, scale=1.0)

        # Pop-out card at frame 180 (6.0s)
        if f_idx >= 180:
            c_rel = clamp((f_idx - 180) / 22)
            c_scale = 0.5 + 0.5 * ease_out_back(c_rel)
            draw_floating_card(
                'Lomé • 33.1°C  En direct',
                'Prévisions fiables ANAMET / AgriDigitale',
                'ACTIF',
                (46, 125, 50),
                y_card=1400,
                alpha=c_rel,
                scale=c_scale
            )

    # ──────────────────────────────────────────────────────────
    # SCENE 3: Prix des Marchés (Frames 285 - 435)
    # ──────────────────────────────────────────────────────────
    elif f_idx < 435:
        p_rel = (f_idx - 285)
        enter = clamp(p_rel / 25)
        phone_x = int(-660 + (W//2 + 330) * ease_out_cubic(enter)) - 330

        draw_badge('COURS DES MARCHES EN TEMPS REEL', 150, alpha=clamp(p_rel / 20))
        draw_titles('Vendez au meilleur prix.', 'Maïs, Soja, Sorgho... mis à jour en direct', y_title=230, y_sub=315, alpha=clamp(p_rel / 25))

        draw_phone(screens_data['prix'], (W - 660)//2, 480, scale=1.0)

        # Pop-out card at frame 330 (11.0s)
        if f_idx >= 330:
            c_rel = clamp((f_idx - 330) / 22)
            c_scale = 0.5 + 0.5 * ease_out_back(c_rel)
            draw_floating_card(
                'Maïs (Bol 2,5 kg) : 400 F',
                'Grand marché de Kara  ▲ Cours Stable',
                'LOCAL',
                (230, 81, 0),
                y_card=1400,
                alpha=c_rel,
                scale=c_scale
            )

    # ──────────────────────────────────────────────────────────
    # SCENE 4: Conseils du Jour (Frames 435 - 585)
    # ──────────────────────────────────────────────────────────
    elif f_idx < 585:
        p_rel = (f_idx - 435)
        draw_badge('CONSEILS DU JOUR D’EXPERTS', 150, alpha=clamp(p_rel / 20))
        draw_titles('Un agronome à vos côtés.', 'Chaque matin à 06h00 : astuces rentables', y_title=230, y_sub=315, alpha=clamp(p_rel / 25))

        draw_phone(screens_data['conseil'], (W - 660)//2, 480, scale=1.0)

        # Push notification drop from top at frame 480 (16.0s)
        if f_idx >= 475:
            n_rel = clamp((f_idx - 475) / 24)
            n_y = int(370 + 960 * ease_out_back(n_rel))
            draw_floating_card(
                'Conseil de 06h00 Débloqué',
                'Rotation des cultures : brisez les maladies',
                'AGRONOME',
                (46, 125, 50),
                y_card=n_y,
                alpha=n_rel,
                scale=1.0
            )

    # ──────────────────────────────────────────────────────────
    # SCENE 5: Mode 100% Hors-Ligne (Frames 585 - 720)
    # ──────────────────────────────────────────────────────────
    elif f_idx < 720:
        p_rel = (f_idx - 585)
        draw_badge('MODE 100% HORS-LIGNE', 150, alpha=clamp(p_rel / 20))
        draw_titles('Zéro connexion ? Aucun souci !', 'Toutes les données disponibles même au champ', y_title=230, y_sub=315, alpha=clamp(p_rel / 25))

        # Floating phone with slight dynamic tilt
        phone_y = int(480 + 15 * math.sin(p_rel * 0.1))
        draw_phone(screens_data['accueil'], (W - 660)//2, phone_y, scale=1.0)

        c_rel = clamp(p_rel / 25)
        draw_floating_card(
            'Mode Hors-Ligne Actif',
            'Synchronisation SQLite instantanée • 0ms',
            'HORS-LIGNE',
            (30, 136, 229),
            y_card=1400,
            alpha=c_rel,
            scale=1.0
        )

    # ──────────────────────────────────────────────────────────
    # SCENE 6: Call To Action Final (Frames 720 - 840)
    # ──────────────────────────────────────────────────────────
    else:
        p_rel = (f_idx - 720)
        p_scale = 0.7 + 0.3 * ease_out_back(clamp(p_rel / 30))

        # Centered Phone with Quiz
        phone_scale = 0.82
        phone_w = int(660 * phone_scale)
        phone_y = 500
        draw_phone(screens_data['quiz'], (W - phone_w)//2, phone_y, scale=phone_scale, alpha=clamp(p_rel / 20))

        # Top Logo + Title
        logo = logo_data
        lw = int(logo.width * 0.22)
        lh = int(logo.height * 0.22)
        logo_scaled = logo.resize((lw, lh), Image.Resampling.LANCZOS)
        frame.paste(logo_scaled, ((W - lw)//2, 90), logo_scaled)

        f_cta_t = ImageFont.truetype(FONT_BOLD, 54)
        cbox = f_cta_t.getbbox('Téléchargez AgriDigitale')
        cx = (W - (cbox[2] - cbox[0])) // 2
        idraw = ImageDraw.Draw(frame)
        idraw.text((cx, 280), 'Téléchargez AgriDigitale', font=f_cta_t, fill=(255, 255, 255, 255))

        # Rating 5 stars
        f_stars = ImageFont.truetype(FONT_SEMI, 30)
        s_text = '★★★★★  4.9 / 5  •  100% Gratuit'
        sbox = f_stars.getbbox(s_text)
        sx = (W - (sbox[2] - sbox[0])) // 2
        idraw.text((sx, 355), s_text, font=f_stars, fill=(255, 214, 0, 255))

        # Pulsing CTA Button
        btn_pulse = 1.0 + 0.03 * math.sin(p_rel * 0.25)
        btn_w = int(680 * btn_pulse)
        btn_h = int(112 * btn_pulse)
        btn_x = (W - btn_w) // 2
        btn_y = 1520

        # Button Glow
        btn_glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        bgdraw = ImageDraw.Draw(btn_glow)
        bgdraw.rounded_rectangle([btn_x - 14, btn_y - 14, btn_x + btn_w + 14, btn_y + btn_h + 14], radius=btn_h//2 + 7, fill=(46, 125, 50, 120))
        btn_glow = btn_glow.filter(ImageFilter.GaussianBlur(28))
        frame = Image.alpha_composite(frame, btn_glow)

        # Button Body
        bdraw = ImageDraw.Draw(frame)
        bdraw.rounded_rectangle([btn_x, btn_y, btn_x + btn_w, btn_y + btn_h], radius=btn_h//2, fill=(46, 125, 50, 255), outline=(129, 199, 132, 255), width=3)

        btn_text = 'INSTALLER SUR GOOGLE PLAY'
        bbox = f_bold_cta.getbbox(btn_text)
        bx = btn_x + (btn_w - (bbox[2] - bbox[0])) // 2
        by = btn_y + (btn_h - (bbox[3] - bbox[1])) // 2 - 3
        bdraw.text((bx, by), btn_text, font=f_bold_cta, fill=(255, 255, 255, 255))

        # Footer
        f_foot = ImageFont.truetype(FONT_SEMI, 26)
        foot_text = 'Rejoignez des milliers de producteurs et passionnés'
        fbox = f_foot.getbbox(foot_text)
        fx = (W - (fbox[2] - fbox[0])) // 2
        fy = 1680
        bdraw.text((fx, fy), foot_text, font=f_foot, fill=(200, 230, 201, 230))

    # Save frame as JPEG for high speed and small disk footprint
    out_path = os.path.join(FRAMES_DIR, f'frame_{f_idx:04d}.jpg')
    frame.convert('RGB').save(out_path, quality=92)
    return f_idx

def render_batch(indices):
    screens = load_and_prep_screenshots()
    logo = Image.open(LOGO_PATH).convert('RGBA')
    for i in indices:
        render_frame_worker(i, screens, logo)

def main():
    print(f'Starting render of {TOTAL_FRAMES} frames ({DURATION_SEC}s @ {FPS}fps)...')
    t0 = time.time()

    # Distribute work across cores
    num_workers = min(8, os.cpu_count() or 4)
    chunk_size = math.ceil(TOTAL_FRAMES / num_workers)
    batches = [range(i * chunk_size, min((i + 1) * chunk_size, TOTAL_FRAMES)) for i in range(num_workers)]

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        futures = [executor.submit(render_batch, list(b)) for b in batches if len(b) > 0]
        for f in futures:
            f.result()

    t1 = time.time()
    print(f'Rendered {TOTAL_FRAMES} frames in {t1 - t0:.1f}s ({(TOTAL_FRAMES/(t1-t0)):.1f} fps)')

    # FFmpeg Encoding with Audio Mixing
    print('Encoding MP4 and mixing sound effects & music...')
    out_mp4 = os.path.join(OUT_DIR, 'AgriDigitale_Promo_Motion.mp4')

    # SFX paths
    boom_sfx = os.path.join(SFX_DIR, 'boom.wav')
    whoosh_sfx = os.path.join(SFX_DIR, 'whoosh.wav')
    pop_sfx = os.path.join(SFX_DIR, 'pop.wav')
    chime_sfx = os.path.join(SFX_DIR, 'chime.wav')
    coin_sfx = os.path.join(BASE_DIR, 'AgriDigitale/frontend/frontend/assets/sounds/quiz_coin.wav')
    correct_sfx = os.path.join(BASE_DIR, 'AgriDigitale/frontend/frontend/assets/sounds/quiz_correct.wav')
    victory_sfx = os.path.join(BASE_DIR, 'AgriDigitale/frontend/frontend/assets/sounds/quiz_victory.wav')
    music = os.path.join(BASE_DIR, 'AgriDigitale/frontend/frontend/assets/sounds/quiz_jungle_marimba_loop.mp3')

    # Complex audio filter:
    # 0: Music looped and padded, volume=0.38
    # 1: boom at 0ms
    # 2: chime at 1800ms
    # 3: whoosh at 4500ms
    # 4: pop at 6000ms
    # 5: whoosh at 9500ms
    # 6: coin at 11000ms
    # 7: whoosh at 14500ms
    # 8: correct at 16000ms
    # 9: whoosh at 19500ms
    # 10: chime at 20500ms
    # 11: whoosh at 24000ms
    # 12: victory at 24500ms
    # 13: boom at 24600ms

    filter_complex = (
        "[1:a]afade=t=in:ss=0:d=0.5,afade=t=out:st=26.5:d=1.5,volume=0.36[a_music];"
        "[2:a]adelay=0|0,volume=1.4[s0];"
        "[3:a]adelay=1800|1800,volume=1.0[s1];"
        "[4:a]adelay=4500|4500,volume=1.2[s2];"
        "[5:a]adelay=6000|6000,volume=1.3[s3];"
        "[6:a]adelay=9500|9500,volume=1.2[s4];"
        "[7:a]adelay=11000|11000,volume=1.5[s5];"
        "[8:a]adelay=14500|14500,volume=1.2[s6];"
        "[9:a]adelay=16000|16000,volume=1.4[s7];"
        "[10:a]adelay=19500|19500,volume=1.2[s8];"
        "[11:a]adelay=20500|20500,volume=1.0[s9];"
        "[12:a]adelay=24000|24000,volume=1.3[s10];"
        "[13:a]adelay=24500|24500,volume=1.5[s11];"
        "[14:a]adelay=24600|24600,volume=1.3[s12];"
        "[a_music][s0][s1][s2][s3][s4][s5][s6][s7][s8][s9][s10][s11][s12]amix=inputs=14:duration=first:dropout_transition=2[a_out]"
    )

    cmd = [
        'ffmpeg', '-y',
        '-framerate', str(FPS),
        '-i', os.path.join(FRAMES_DIR, 'frame_%04d.jpg'),
        '-i', music,
        '-i', boom_sfx,
        '-i', chime_sfx,
        '-i', whoosh_sfx,
        '-i', pop_sfx,
        '-i', whoosh_sfx,
        '-i', coin_sfx,
        '-i', whoosh_sfx,
        '-i', correct_sfx,
        '-i', whoosh_sfx,
        '-i', chime_sfx,
        '-i', whoosh_sfx,
        '-i', victory_sfx,
        '-i', boom_sfx,
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
    print(f'SUCCESS! Video rendered at: {out_mp4} (Total processing time: {t2-t0:.1f}s)')

if __name__ == '__main__':
    main()
