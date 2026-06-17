"""사용자 첨부 K-Puzzles 아이콘 소스 → 3종 자산 생성.

입력: assets/app_icon_source.png (사용자 첨부 원본)
출력:
- assets/app_icon.png            : 1024x1024, 네이비 배경 + 마크 (런처/스토어용)
- assets/app_icon_foreground.png : 1024x1024, 마크만(투명 배경) + 78% 안전영역
- assets/app_icon_monochrome.png : 1024x1024, 흰색 단색 마크 (Android Themed Icon)
"""
import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W = 1024
SRC = "assets/app_icon_source.png"
OUT_FULL = "assets/app_icon.png"
OUT_FG = "assets/app_icon_foreground.png"
OUT_MONO = "assets/app_icon_monochrome.png"

# Adaptive icon foreground 안전 영역 비율
SAFE_SCALE = 0.78


def to_square(img: Image.Image, fill_color) -> Image.Image:
    """직사각 이미지를 정사각으로 패딩 (배경색으로 채움)"""
    w, h = img.size
    if w == h:
        return img
    side = max(w, h)
    out = Image.new("RGBA", (side, side), fill_color)
    out.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return out


def make_rounded_square(side: int, color, radius: int) -> Image.Image:
    """둥근 사각 배경 생성"""
    bg = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    draw = ImageDraw.Draw(bg)
    draw.rounded_rectangle((0, 0, side, side), radius=radius, fill=color)
    return bg


def extract_mark(img_rgba: Image.Image, bg_color, threshold=70) -> Image.Image:
    """배경색 근처 픽셀을 투명으로 변환해 마크만 남김.

    bg_color: (R, G, B) 또는 (R, G, B, A)
    threshold: 색상 유클리드 거리 임계값
    """
    arr = np.array(img_rgba)  # (H, W, 4)
    h, w = arr.shape[:2]
    bg_rgb = np.array(bg_color[:3], dtype=np.int16)

    rgb = arr[:, :, :3].astype(np.int16)
    diff = rgb - bg_rgb[np.newaxis, np.newaxis, :]
    dist = np.sqrt((diff ** 2).sum(axis=2))

    mask = dist < threshold  # True = 배경
    out_alpha = arr[:, :, 3].copy()
    out_alpha[mask] = 0  # 배경 픽셀 투명화

    # 가장자리 부드럽게 — alpha를 거리 기반으로 부드러운 계조
    # threshold 부근에서 점진적 페이드아웃
    fade_range = 25
    soft_zone = (dist >= threshold) & (dist < threshold + fade_range)
    fade_strength = ((dist - threshold) / fade_range).clip(0, 1)
    out_alpha[soft_zone] = (out_alpha[soft_zone].astype(float) * fade_strength[soft_zone]).astype(np.uint8)

    arr[:, :, 3] = out_alpha
    return Image.fromarray(arr, "RGBA")


def make_monochrome(mark_rgba: Image.Image) -> Image.Image:
    """마크 영역(alpha)을 흰색으로만 채운 단색 버전"""
    arr = np.array(mark_rgba)
    mono = np.zeros_like(arr)
    mono[:, :, 0] = 255
    mono[:, :, 1] = 255
    mono[:, :, 2] = 255
    mono[:, :, 3] = arr[:, :, 3]  # 형태 유지, 흰색으로
    return Image.fromarray(mono, "RGBA")


def scale_into_canvas(img: Image.Image, canvas_size: int, scale: float) -> Image.Image:
    """캔버스 가운데에 마크를 scale 비율로 배치"""
    new_size = int(canvas_size * scale)
    small = img.resize((new_size, new_size), Image.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = (canvas_size - new_size) // 2
    canvas.alpha_composite(small, (offset, offset))
    return canvas


def main():
    src_path = SRC
    if not os.path.exists(src_path):
        raise FileNotFoundError(src_path)

    src = Image.open(src_path).convert("RGBA")
    print(f"Loaded: {src.size}, mode={src.mode}")

    # 1. 배경색 샘플 (좌상단 모서리 영역 평균)
    arr = np.array(src)
    corner = arr[5:15, 5:15, :3]
    bg_color = tuple(int(v) for v in corner.reshape(-1, 3).mean(axis=0))
    print(f"Background sample: {bg_color}")

    # 2. 정사각으로 패딩 (배경색으로 채움)
    bg_fill = bg_color + (255,)
    squared = to_square(src, bg_fill)
    print(f"Squared: {squared.size}")

    # 3. 1024로 리사이즈
    squared_1024 = squared.resize((W, W), Image.LANCZOS)

    # 4. app_icon.png — 둥근 사각 배경 위에 합성
    # 원본이 거의 정사각이고 모서리가 직각이라, 둥근 사각 안에 합성하여 어떤 마스킹에도 자연스럽게
    round_bg = make_rounded_square(W, bg_fill, radius=224)
    # 원본을 살짝 축소 (모서리 마스킹 영역 확보 — 약 95%)
    src_inset = squared_1024.resize((int(W * 0.95), int(W * 0.95)), Image.LANCZOS)
    margin = (W - src_inset.width) // 2
    full = round_bg.copy()
    full.alpha_composite(src_inset, (margin, margin))
    full.save(OUT_FULL, "PNG")
    print(f"Saved: {OUT_FULL}")

    # 5. app_icon_foreground.png — 마크만 추출 후 78% 안전영역에 배치
    mark_only = extract_mark(squared_1024, bg_color, threshold=70)
    fg = scale_into_canvas(mark_only, W, SAFE_SCALE)
    fg.save(OUT_FG, "PNG")
    print(f"Saved: {OUT_FG}")

    # 6. app_icon_monochrome.png — 흰색 단색
    mono_mark = make_monochrome(mark_only)
    mono = scale_into_canvas(mono_mark, W, SAFE_SCALE)
    mono.save(OUT_MONO, "PNG")
    print(f"Saved: {OUT_MONO}")


if __name__ == "__main__":
    main()
