"""
Ninedoku Google Play Store 데모 영상 생성
- 실제 디바이스 스크린샷 기반
- 폰 프레임 + 캡션 + 크로스페이드 전환
"""

import os
import sys
import cv2
import numpy as np
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = Path(r"D:\00. Workspace\sudoku\tools")
SS_DIR = BASE_DIR / "device_screenshots"
OUT_PATH = str(BASE_DIR / "ninedoku_demo.mp4")

FPS = 30
HOLD_SEC = 2.5       # 장면 유지
TRANS_SEC = 0.5       # 크로스페이드
VW, VH = 1080, 1920  # 출력 해상도 (세로 FHD)

FONT_B = "C:/Windows/Fonts/malgunbd.ttf"
FONT_R = "C:/Windows/Fonts/malgun.ttf"
BG = (15, 15, 25)


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()


def center_text(draw, y, text, fnt, fill, w):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, y), text, fill=fill, font=fnt)
    return bbox[3] - bbox[1]


def gradient_line(draw, y, w, h=4):
    for x in range(w):
        r = x / w
        c = (int(70 + 50 * r), int(130 + 40 * r), int(240 + 15 * r))
        draw.line([(x, y), (x, y + h - 1)], fill=c)


# ========== 프레임 생성 ==========

def title_frame(title, subtitle=""):
    img = Image.new('RGB', (VW, VH), BG)
    d = ImageDraw.Draw(img)
    gradient_line(d, VH // 2 - 140, VW)
    gradient_line(d, VH // 2 + 120, VW)
    center_text(d, VH // 2 - 100, title, font(FONT_B, 120), (255, 255, 255), VW)
    if subtitle:
        center_text(d, VH // 2 + 30, subtitle, font(FONT_R, 52), (170, 180, 210), VW)
    return np.array(img)


def feature_frame(text, sub=""):
    img = Image.new('RGB', (VW, VH), BG)
    d = ImageDraw.Draw(img)
    # 장식 원
    cx, cy = VW // 2, VH // 2 - 100
    for r in range(100, 0, -1):
        a = r / 100
        d.ellipse([cx - r, cy - r, cx + r, cy + r],
                  fill=(int(35 * a), int(70 * a), int(160 * a)))
    pts = [(cx, cy - 35), (cx + 30, cy), (cx, cy + 35), (cx - 30, cy)]
    d.polygon(pts, fill=(100, 165, 255))
    center_text(d, VH // 2 + 40, text, font(FONT_B, 64), (255, 255, 255), VW)
    if sub:
        center_text(d, VH // 2 + 120, sub, font(FONT_R, 40), (140, 150, 180), VW)
    return np.array(img)


def screenshot_frame(path, caption):
    """스크린샷 + 캡션 프레임"""
    img = Image.new('RGB', (VW, VH), BG)
    d = ImageDraw.Draw(img)

    ss = Image.open(path)
    ss_w, ss_h = ss.size

    # 스크린 영역 (상하 여백 확보)
    max_h = int(VH * 0.82)
    max_w = int(VW * 0.88)
    ratio = min(max_w / ss_w, max_h / ss_h)
    new_w = int(ss_w * ratio)
    new_h = int(ss_h * ratio)
    ss = ss.resize((new_w, new_h), Image.LANCZOS)

    # 폰 프레임 (라운드 테두리)
    pad = 8
    fx = (VW - new_w) // 2 - pad
    fy = 40 - pad
    # 외곽 프레임
    frame = Image.new('RGB', (new_w + pad * 2, new_h + pad * 2), (55, 60, 75))
    img.paste(frame, (fx, fy))
    # 스크린샷
    img.paste(ss, ((VW - new_w) // 2, 40))

    # 캡션
    cap_y = 40 + new_h + 30
    center_text(d, cap_y, caption, font(FONT_B, 48), (210, 220, 240), VW)

    return np.array(img)


def crossfade(f1, f2, steps):
    out = []
    for i in range(steps):
        a = i / max(steps, 1)
        out.append(cv2.addWeighted(f1, 1 - a, f2, a, 0).astype(np.uint8))
    return out


# ========== 장면 순서 정의 ==========

def build_scenes():
    """영상 장면 목록 생성"""
    scenes = []

    # (1) 오프닝
    scenes.append(title_frame("Ninedoku", "Offline Sudoku"))

    # (2) 콘셉트
    scenes.append(feature_frame("완전 오프라인 스도쿠", "인터넷 없이, 언제 어디서든"))

    # (3) 스크린샷 — 사용자 플로우 순서
    screen_order = [
        ("06_home.png",        "깔끔한 홈 화면"),
        ("07_gamemode.png",    "다양한 게임 모드"),
        ("10_selectlevel.png", "6단계 난이도"),
        ("05_gameplay.png",    "직관적인 게임 플레이"),
        ("04_completion.png",  "게임 완료 & 배지 획득"),
        ("08_resume.png",      "이어하기 지원"),
        ("11_today.png",       "오늘의 퍼즐"),
        ("90_todayplay.png",   "매일 새로운 도전"),
        ("03_statistics.png",  "상세한 통계"),
        ("02_badges.png",      "배지 수집"),
        ("01_settings.png",    "맞춤 설정"),
    ]

    for filename, caption in screen_order:
        path = SS_DIR / filename
        if path.exists():
            scenes.append(screenshot_frame(str(path), caption))
            print(f"  + {filename} -> {caption}")

    # (4) 핵심 기능 요약
    scenes.append(feature_frame("자동완성 & Perfect", "실수 없이 완주하면 자동 완성"))
    scenes.append(feature_frame("개인정보 수집 없음", "완전한 프라이버시 보호"))

    # (5) 엔딩
    scenes.append(title_frame("Ninedoku", "지금 바로 다운로드하세요"))

    return scenes


# ========== 영상 합성 ==========

def build_video(scenes):
    hold = int(HOLD_SEC * FPS)
    trans = int(TRANS_SEC * FPS)

    writer = cv2.VideoWriter(OUT_PATH, cv2.VideoWriter_fourcc(*'mp4v'), FPS, (VW, VH))

    total = len(scenes)
    prev = None
    for i, frame_rgb in enumerate(scenes):
        bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)
        bgr = cv2.resize(bgr, (VW, VH))

        if prev is not None:
            for tf in crossfade(prev, bgr, trans):
                writer.write(tf)

        for _ in range(hold):
            writer.write(bgr)

        prev = bgr
        print(f"  장면 {i + 1}/{total}")

    writer.release()

    sz = os.path.getsize(OUT_PATH) / 1024 / 1024
    dur = total * (HOLD_SEC + TRANS_SEC) - TRANS_SEC
    print(f"\n영상 완료!")
    print(f"  파일: {OUT_PATH}")
    print(f"  크기: {sz:.1f} MB")
    print(f"  해상도: {VW}x{VH}")
    print(f"  길이: ~{dur:.0f}초")


# ========== 메인 ==========

def main():
    print("=" * 50)
    print("  Ninedoku 데모 영상 생성기 v3")
    print("=" * 50)

    print(f"\n스크린샷 폴더: {SS_DIR}")
    files = list(SS_DIR.glob("*.png"))
    print(f"발견된 스크린샷: {len(files)}장\n")

    print("[1/2] 장면 구성...")
    scenes = build_scenes()
    print(f"\n총 {len(scenes)}개 장면\n")

    print("[2/2] MP4 합성...")
    build_video(scenes)


if __name__ == "__main__":
    main()
