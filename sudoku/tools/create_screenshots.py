"""
Google Play Store 스크린샷 생성기
- 원본 디바이스 캡처 → 폰 프레임 + 캡션 + 다크 배경
- 출력: 1080x1920 PNG x 8장
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BASE_DIR = Path(r"D:\00. Workspace\sudoku\tools")
SS_DIR = BASE_DIR / "device_screenshots"
OUT_DIR = BASE_DIR / "store_assets" / "screenshots"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# 출력 규격
W, H = 1080, 1920

# 폰트
FONT_B = "C:/Windows/Fonts/malgunbd.ttf"
FONT_R = "C:/Windows/Fonts/malgun.ttf"

# 색상
BG_TOP = (12, 14, 28)
BG_BOT = (18, 26, 50)
ACCENT = (74, 144, 217)  # #4A90D9 — 앱 아이콘 배경색


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()


def draw_vertical_gradient(img, top, bot):
    """세로 그라데이션"""
    d = ImageDraw.Draw(img)
    w, h = img.size
    for y in range(h):
        ratio = y / h
        r = int(top[0] + (bot[0] - top[0]) * ratio)
        g = int(top[1] + (bot[1] - top[1]) * ratio)
        b = int(top[2] + (bot[2] - top[2]) * ratio)
        d.line([(0, y), (w, y)], fill=(r, g, b))


def draw_gradient_line(draw, x1, y, x2, h=3):
    """수평 그라데이션 라인 (중앙이 밝고 양쪽이 투명)"""
    length = x2 - x1
    mid = length // 2
    for i in range(length):
        dist = abs(i - mid) / mid  # 0(중앙) ~ 1(끝)
        alpha = max(0, 1.0 - dist * 1.2)
        r = int(ACCENT[0] * alpha + 40 * (1 - alpha))
        g = int(ACCENT[1] * alpha + 60 * (1 - alpha))
        b = int(ACCENT[2] * alpha + 120 * (1 - alpha))
        brightness = int(255 * alpha)
        if brightness > 10:
            draw.line([(x1 + i, y), (x1 + i, y + h - 1)],
                     fill=(r, g, b))


def center_text(draw, y, text, fnt, fill, canvas_w):
    """중앙 정렬 텍스트, 높이 반환"""
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (canvas_w - tw) // 2
    draw.text((x, y), text, fill=fill, font=fnt)
    return th


def create_phone_frame(screenshot_path, phone_h):
    """스크린샷에 폰 프레임 씌우기"""
    ss = Image.open(screenshot_path).convert('RGBA')
    ss_w, ss_h = ss.size

    # 폰 프레임 내부에 맞게 리사이즈
    ratio = phone_h / ss_h
    new_w = int(ss_w * ratio)
    new_h = phone_h
    ss = ss.resize((new_w, new_h), Image.LANCZOS)

    # 프레임 파라미터
    bezel = 10
    corner_r = 28
    total_w = new_w + bezel * 2
    total_h = new_h + bezel * 2

    # 그림자 레이어
    shadow_pad = 30
    shadow = Image.new('RGBA',
                       (total_w + shadow_pad * 2, total_h + shadow_pad * 2),
                       (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        [shadow_pad, shadow_pad,
         shadow_pad + total_w - 1, shadow_pad + total_h - 1],
        radius=corner_r + 6,
        fill=(0, 0, 0, 100)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=15))

    # 프레임 레이어
    frame = Image.new('RGBA', (total_w, total_h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    # 외부 프레임 (진한 회색)
    fd.rounded_rectangle(
        [0, 0, total_w - 1, total_h - 1],
        radius=corner_r,
        fill=(50, 55, 70, 255)
    )
    # 내부 영역 (스크린)
    fd.rounded_rectangle(
        [bezel, bezel, bezel + new_w - 1, bezel + new_h - 1],
        radius=corner_r - 6,
        fill=(0, 0, 0, 255)
    )

    # 스크린샷 합성
    frame.paste(ss, (bezel, bezel), ss)

    return frame, shadow, shadow_pad


def create_screenshot(index, filename, title, subtitle):
    """하나의 Play Store 스크린샷 생성"""
    ss_path = SS_DIR / filename
    if not ss_path.exists():
        print(f"  ⚠ {filename} 없음 — 건너뜀")
        return False

    # 캔버스 생성 (세로 그라데이션 배경)
    canvas = Image.new('RGB', (W, H), BG_TOP)
    draw_vertical_gradient(canvas, BG_TOP, BG_BOT)
    canvas = canvas.convert('RGBA')

    # 미세한 장식: 상단/하단 글로우
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    # 상단 글로우
    for r in range(350, 0, -3):
        a = int(12 * (r / 350))
        gd.ellipse([W // 2 - r, -200 - r, W // 2 + r, -200 + r],
                   fill=(ACCENT[0], ACCENT[1], ACCENT[2], a))
    canvas = Image.alpha_composite(canvas, glow)

    d = ImageDraw.Draw(canvas)

    # === 상단 텍스트 영역 ===
    # 타이틀 (큰 볼드)
    title_y = 120
    title_font = font(FONT_B, 72)
    th = center_text(d, title_y, title, title_font, (255, 255, 255, 255), W)

    # 구분선
    line_y = title_y + th + 30
    draw_gradient_line(d, W // 2 - 160, line_y, W // 2 + 160, h=3)

    # 서브타이틀
    sub_y = line_y + 24
    sub_font = font(FONT_R, 36)
    center_text(d, sub_y, subtitle, sub_font, (160, 175, 210, 230), W)

    # === 폰 프레임 + 스크린샷 ===
    phone_top = sub_y + 100
    phone_h = H - phone_top - 80  # 하단 여백

    frame, shadow, shadow_pad = create_phone_frame(ss_path, phone_h)
    fw, fh = frame.size

    # 중앙 정렬
    fx = (W - fw) // 2
    fy = phone_top

    # 그림자 배치
    canvas.paste(shadow,
                 (fx - shadow_pad, fy - shadow_pad + 8),
                 shadow)

    # 프레임 배치
    canvas.paste(frame, (fx, fy), frame)

    # === 하단 브랜딩 (미세하게) ===
    brand_font = font(FONT_R, 24)
    # 하단 여백이 충분하면 브랜드명 추가
    brand_y = H - 55
    center_text(d, brand_y, "Ninedoku", brand_font, (80, 90, 120, 150), W)

    # === 저장 ===
    final = canvas.convert('RGB')
    out_path = OUT_DIR / f"{index:02d}_{Path(filename).stem}.png"
    final.save(str(out_path), 'PNG', optimize=True)

    size_kb = out_path.stat().st_size / 1024
    print(f"  ✓ [{index}] {filename} → {out_path.name} ({size_kb:.0f} KB)")
    return True


# ============================================================
# 스크린샷 목록 (마케팅 최적화 순서)
# ============================================================
SCREENSHOTS = [
    ("06_home.png",        "깔끔한 홈 화면",         "한눈에 보는 모든 기능"),
    ("05_gameplay.png",    "직관적인 플레이",         "터치 한 번으로 숫자 입력"),
    ("07_gamemode.png",    "3가지 게임 모드",         "클래식 · 릴렉스 · 오늘의 퍼즐"),
    ("10_selectlevel.png", "6단계 난이도",            "초보부터 고수까지"),
    ("04_completion.png",  "달성의 쾌감",             "게임 완료 & 배지 획득"),
    ("11_today.png",       "매일 새로운 도전",        "오늘의 퍼즐로 꾸준히"),
    ("03_statistics.png",  "나의 성장 기록",          "상세한 통계로 실력 확인"),
    ("02_badges.png",      "배지 수집",              "도전 과제 달성의 재미"),
]


def main():
    print("=" * 50)
    print("  Play Store 스크린샷 생성기")
    print("=" * 50)
    print(f"  출력: {W}x{H} PNG")
    print(f"  폴더: {OUT_DIR}\n")

    count = 0
    for i, (filename, title, subtitle) in enumerate(SCREENSHOTS, 1):
        if create_screenshot(i, filename, title, subtitle):
            count += 1

    print(f"\n  총 {count}장 생성 완료!")
    print(f"  폴더: {OUT_DIR}")
    print("=" * 50)


if __name__ == "__main__":
    main()
