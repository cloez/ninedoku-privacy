"""
Google Play Store 에셋 생성기
1) 앱 아이콘 512x512 (기존 foreground + 배경 합성)
2) 그래픽 이미지 1024x500 (Feature Graphic)
"""

import sys
import math
sys.stdout.reconfigure(encoding='utf-8')

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BASE_DIR = Path(r"D:\00. Workspace\sudoku\tools")
RES_DIR = Path(r"D:\00. Workspace\sudoku\android\app\src\main\res")
SS_DIR = BASE_DIR / "device_screenshots"
OUT_DIR = BASE_DIR / "store_assets"
OUT_DIR.mkdir(exist_ok=True)

FONT_B = "C:/Windows/Fonts/malgunbd.ttf"
FONT_R = "C:/Windows/Fonts/malgun.ttf"

# 앱 배경색
BG_COLOR = (74, 144, 217)  # #4A90D9


def font(path, size):
    """폰트 로드"""
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()


def create_rounded_rect(size, radius, color):
    """라운드 사각형 이미지 생성"""
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=color)
    return img


# ============================================================
# 1. 앱 아이콘 512x512
# ============================================================
def create_app_icon():
    print("[1/2] 앱 아이콘 생성 (512x512)...")

    # 기존 foreground 이미지 (가장 큰 해상도)
    fg_path = RES_DIR / "drawable-xxxhdpi" / "ic_launcher_foreground.png"
    fg = Image.open(fg_path).convert('RGBA')
    fg_size = fg.size[0]
    print(f"  foreground 원본: {fg.size}")

    # 512x512 캔버스 (배경색)
    icon_size = 512

    # 배경: 라운드 사각형
    radius = int(icon_size * 0.22)  # Play Store 표준 라운딩
    bg = create_rounded_rect((icon_size, icon_size), radius, BG_COLOR + (255,))

    # foreground를 adaptive icon 규격에 맞게 리사이즈
    # adaptive icon: foreground는 108dp 중 72dp 영역에 표시 (66.7%)
    # 16% inset이 적용되어 있으므로 foreground 자체가 이미 패딩 포함
    # 512px 기준으로 foreground를 맞춤
    fg_resized = fg.resize((icon_size, icon_size), Image.LANCZOS)

    # 합성
    bg.paste(fg_resized, (0, 0), fg_resized)

    # RGBA -> RGB (Play Store는 알파 없는 PNG 권장)
    final = Image.new('RGB', (icon_size, icon_size), (255, 255, 255))
    final.paste(bg, (0, 0), bg)

    out_path = OUT_DIR / "app_icon_512.png"
    final.save(str(out_path), 'PNG', optimize=True)
    print(f"  저장: {out_path}")
    print(f"  크기: {out_path.stat().st_size / 1024:.1f} KB")
    return final


# ============================================================
# 2. 그래픽 이미지 1024x500 (Feature Graphic)
# ============================================================
def draw_gradient_bg(img, color1, color2):
    """수평 그라데이션 배경"""
    d = ImageDraw.Draw(img)
    w, h = img.size
    for x in range(w):
        ratio = x / w
        r = int(color1[0] + (color2[0] - color1[0]) * ratio)
        g = int(color1[1] + (color2[1] - color1[1]) * ratio)
        b = int(color1[2] + (color2[2] - color1[2]) * ratio)
        d.line([(x, 0), (x, h)], fill=(r, g, b))
    return img


def draw_radial_glow(img, cx, cy, radius, color, alpha=40):
    """부드러운 원형 글로우 효과"""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for r in range(radius, 0, -2):
        a = int(alpha * (r / radius))
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=color + (a,))
    return Image.alpha_composite(img.convert('RGBA'), overlay)


def draw_grid_pattern(draw, w, h, spacing=60, color=(255, 255, 255, 12)):
    """미세한 그리드 패턴 (스도쿠 느낌)"""
    for x in range(0, w, spacing):
        draw.line([(x, 0), (x, h)], fill=color, width=1)
    for y in range(0, h, spacing):
        draw.line([(0, y), (w, y)], fill=color, width=1)
    # 3x3 두꺼운 선 (스도쿠 박스)
    box_spacing = spacing * 3
    for x in range(0, w, box_spacing):
        draw.line([(x, 0), (x, h)], fill=(255, 255, 255, 25), width=2)
    for y in range(0, h, box_spacing):
        draw.line([(0, y), (w, y)], fill=(255, 255, 255, 25), width=2)


def center_text_x(draw, y, text, fnt, fill, canvas_w, anchor_x=None):
    """텍스트 중앙 또는 지정 X 정렬"""
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = anchor_x - tw // 2 if anchor_x else (canvas_w - tw) // 2
    draw.text((x, y), text, fill=fill, font=fnt)
    return th


def create_feature_graphic(app_icon):
    print("\n[2/2] 그래픽 이미지 생성 (1024x500)...")

    W, H = 1024, 500

    # --- 배경: 다크 그라데이션 ---
    bg = Image.new('RGB', (W, H), (12, 14, 28))
    bg = draw_gradient_bg(bg, (12, 14, 28), (18, 28, 55))

    # RGBA로 변환하여 작업
    canvas = bg.convert('RGBA')

    # --- 장식: 글로우 효과 ---
    canvas = draw_radial_glow(canvas, W // 4, H // 2, 300, (50, 100, 200))
    canvas = draw_radial_glow(canvas, int(W * 0.75), H // 2, 250, (30, 70, 160))

    # --- 장식: 스도쿠 그리드 패턴 ---
    grid_overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    grid_draw = ImageDraw.Draw(grid_overlay)
    draw_grid_pattern(grid_draw, W, H, spacing=50)
    canvas = Image.alpha_composite(canvas, grid_overlay)

    # --- 왼쪽: 텍스트 영역 ---
    d = ImageDraw.Draw(canvas)

    text_center_x = int(W * 0.27)

    # 앱 이름
    title_font = font(FONT_B, 72)
    center_text_x(d, 110, "Ninedoku", title_font, (255, 255, 255, 255), W, text_center_x)

    # 구분선
    line_y = 200
    line_w = 260
    lx = text_center_x - line_w // 2
    for x in range(line_w):
        ratio = x / line_w
        r = int(60 + 80 * ratio)
        g = int(120 + 60 * ratio)
        b = int(220 + 35 * ratio)
        a = int(200 * (1 - abs(ratio - 0.5) * 2))
        d.line([(lx + x, line_y), (lx + x, line_y + 2)], fill=(r, g, b, a))

    # 슬로건
    slogan_font = font(FONT_R, 32)
    center_text_x(d, 225, "Pure Offline Sudoku", slogan_font, (170, 185, 220, 255), W, text_center_x)

    # 배지들 — 별도 RGBA 레이어에 그려서 합성
    badge_y = 295
    badges = [
        ("No Ads", (90, 210, 120)),
        ("No Internet", (100, 170, 255)),
        ("No Data", (220, 140, 90)),
    ]

    badge_padding_h = 12
    badge_padding_w = 22
    badge_gap = 16
    badge_font = font(FONT_B, 22)

    # 배지 너비 계산
    badge_dims = []
    total_badge_w = 0
    for label, _ in badges:
        bbox = d.textbbox((0, 0), label, font=badge_font)
        bw = bbox[2] - bbox[0] + badge_padding_w * 2
        bh = bbox[3] - bbox[1] + badge_padding_h * 2
        badge_dims.append((bw, bh))
        total_badge_w += bw

    total_badge_w += badge_gap * (len(badges) - 1)
    bx = text_center_x - total_badge_w // 2

    # 배지 전용 레이어
    badge_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(badge_layer)

    for i, ((label, color), (bw, bh)) in enumerate(zip(badges, badge_dims)):
        # 배지 배경 (반투명)
        bd.rounded_rectangle(
            [bx, badge_y, bx + bw, badge_y + bh],
            radius=bh // 2,
            fill=(color[0], color[1], color[2], 50),
            outline=(color[0], color[1], color[2], 160),
            width=2
        )
        # 배지 텍스트 (밝은 색)
        bbox = bd.textbbox((0, 0), label, font=badge_font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        bd.text(
            (bx + (bw - tw) // 2, badge_y + (bh - th) // 2 - 1),
            label,
            fill=(color[0], color[1], color[2], 255),
            font=badge_font
        )
        bx += bw + badge_gap

    canvas = Image.alpha_composite(canvas, badge_layer)
    d = ImageDraw.Draw(canvas)  # Draw 재생성

    # 하단 부가 정보
    sub_font = font(FONT_R, 20)
    center_text_x(d, 370, "6 Levels  |  Daily Puzzle  |  Badges & Stats", sub_font,
                  (140, 155, 195, 230), W, text_center_x)

    # --- 오른쪽: 폰 목업 (스크린샷 2장) ---
    # 메인 스크린샷 (게임플레이)
    ss_main_path = SS_DIR / "05_gameplay.png"
    ss_sub_path = SS_DIR / "06_home.png"

    if ss_main_path.exists() and ss_sub_path.exists():
        # 폰 프레임 영역
        phone_area_x = int(W * 0.58)

        # 메인 폰 (앞쪽, 더 크게)
        ss_main = Image.open(ss_main_path)
        main_h = int(H * 0.88)
        main_ratio = main_h / ss_main.height
        main_w = int(ss_main.width * main_ratio)
        ss_main = ss_main.resize((main_w, main_h), Image.LANCZOS)

        # 폰 프레임 (라운드 테두리 + 그림자)
        frame_pad = 6
        frame_radius = 18

        # 그림자
        shadow = Image.new('RGBA', (main_w + frame_pad * 2 + 20, main_h + frame_pad * 2 + 20), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle([10, 10, main_w + frame_pad * 2 + 9, main_h + frame_pad * 2 + 9],
                            radius=frame_radius + 4, fill=(0, 0, 0, 80))
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=8))

        main_x = phone_area_x + 40
        main_y = (H - main_h) // 2

        canvas.paste(shadow, (main_x - frame_pad - 10, main_y - frame_pad - 5), shadow)

        # 프레임
        frame = Image.new('RGBA', (main_w + frame_pad * 2, main_h + frame_pad * 2), (0, 0, 0, 0))
        fd = ImageDraw.Draw(frame)
        fd.rounded_rectangle([0, 0, frame.width - 1, frame.height - 1],
                            radius=frame_radius, fill=(45, 50, 65, 255))
        canvas.paste(frame, (main_x - frame_pad, main_y - frame_pad), frame)

        # 스크린샷
        ss_main_rgba = ss_main.convert('RGBA')
        canvas.paste(ss_main_rgba, (main_x, main_y), ss_main_rgba)

        # 서브 폰 (뒤쪽, 약간 작게, 왼쪽에 살짝 겹침)
        ss_sub = Image.open(ss_sub_path)
        sub_h = int(H * 0.76)
        sub_ratio = sub_h / ss_sub.height
        sub_w = int(ss_sub.width * sub_ratio)
        ss_sub = ss_sub.resize((sub_w, sub_h), Image.LANCZOS)

        sub_x = phone_area_x - sub_w // 6
        sub_y = (H - sub_h) // 2 + 20

        # 서브 그림자
        shadow2 = Image.new('RGBA', (sub_w + frame_pad * 2 + 20, sub_h + frame_pad * 2 + 20), (0, 0, 0, 0))
        sd2 = ImageDraw.Draw(shadow2)
        sd2.rounded_rectangle([10, 10, sub_w + frame_pad * 2 + 9, sub_h + frame_pad * 2 + 9],
                             radius=frame_radius + 4, fill=(0, 0, 0, 60))
        shadow2 = shadow2.filter(ImageFilter.GaussianBlur(radius=6))
        canvas.paste(shadow2, (sub_x - frame_pad - 10, sub_y - frame_pad - 5), shadow2)

        # 서브 프레임
        frame2 = Image.new('RGBA', (sub_w + frame_pad * 2, sub_h + frame_pad * 2), (0, 0, 0, 0))
        fd2 = ImageDraw.Draw(frame2)
        fd2.rounded_rectangle([0, 0, frame2.width - 1, frame2.height - 1],
                             radius=frame_radius, fill=(40, 45, 60, 255))
        canvas.paste(frame2, (sub_x - frame_pad, sub_y - frame_pad), frame2)

        # 서브 스크린샷 (약간 투명하게)
        ss_sub_rgba = ss_sub.convert('RGBA')
        # 살짝 어둡게 (뒤에 있는 느낌)
        dark_overlay = Image.new('RGBA', (sub_w, sub_h), (0, 0, 0, 30))
        ss_sub_final = Image.alpha_composite(ss_sub_rgba, dark_overlay)
        canvas.paste(ss_sub_final, (sub_x, sub_y), ss_sub_final)

        print(f"  스크린샷 배치: gameplay({main_w}x{main_h}), home({sub_w}x{sub_h})")
    else:
        print("  경고: 스크린샷 파일 누락!")

    # --- 최종 출력 ---
    final = canvas.convert('RGB')
    out_path = OUT_DIR / "feature_graphic_1024x500.png"
    final.save(str(out_path), 'PNG', optimize=True)
    print(f"  저장: {out_path}")
    print(f"  크기: {out_path.stat().st_size / 1024:.1f} KB")

    return final


# ============================================================
# 메인
# ============================================================
def main():
    print("=" * 50)
    print("  Play Store 그래픽 에셋 생성기")
    print("=" * 50)
    print(f"  출력 폴더: {OUT_DIR}\n")

    icon = create_app_icon()
    feature = create_feature_graphic(icon)

    print("\n" + "=" * 50)
    print("  완료! 생성된 파일:")
    print(f"  1. {OUT_DIR / 'app_icon_512.png'}")
    print(f"  2. {OUT_DIR / 'feature_graphic_1024x500.png'}")
    print("=" * 50)


if __name__ == "__main__":
    main()
