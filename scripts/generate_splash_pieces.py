"""스플래시 애니메이션용 K 조각 4개(색상별) 추출.

assets/app_icon_source.png에서 색상별 마스크로 4개의 캡슐을 분리.
배경(네이비)은 모두 투명 처리. 각 조각은 원본 캔버스 좌표를 유지하므로
Flutter에서 같은 위치에 4장을 겹치면 원본 K가 완벽히 복원된다.

출력 (각 정사각, 투명 배경):
- assets/splash_piece_blue.png    — 좌상 파랑 캡슐
- assets/splash_piece_orange.png  — 우상 주황 대각
- assets/splash_piece_purple.png  — 좌하 보라 캡슐
- assets/splash_piece_green.png   — 우하 초록 대각
"""
import os
import cv2
import numpy as np
from PIL import Image

SRC = "assets/app_icon_source.png"
OUT_DIR = "assets"

# OpenCV HSV 색상 범위 (H: 0~179, S/V: 0~255)
# 각 캡슐의 글로우/그림자까지 포함되도록 폭 넓게.
COLOR_RANGES = {
    "blue":   ((85, 90, 100),  (115, 255, 255)),
    "orange": ((8, 130, 130),  (28, 255, 255)),
    "purple": ((125, 60, 60),  (160, 255, 255)),
    "green":  ((42, 90, 80),   (80, 255, 255)),
}


def to_square_canvas(src: Image.Image) -> Image.Image:
    """정사각으로 패딩 (배경색 추정 후 투명)"""
    w, h = src.size
    side = max(w, h)
    out = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    out.paste(src, ((side - w) // 2, (side - h) // 2), src)
    return out


def extract_by_color(square: Image.Image, lo, hi) -> Image.Image:
    """HSV 마스크로 색상 영역만 남기고, 가장 큰 연결 영역만 사용"""
    arr = np.array(square)
    bgr = cv2.cvtColor(arr[:, :, :3], cv2.COLOR_RGB2BGR)
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv, np.array(lo), np.array(hi))

    # 모폴로지로 노이즈 제거 + 내부 메우기
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=3)

    # 가장 큰 연결 영역만 남김 — 작은 노이즈 컴포넌트 제거
    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    if num_labels > 1:
        # label 0은 배경. 1번부터 비교.
        largest_idx = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        mask = (labels == largest_idx).astype(np.uint8) * 255

    # 살짝 확장 (캡슐 외곽 글로우 포함)
    mask = cv2.dilate(mask, kernel, iterations=1)
    # 부드러운 가장자리
    mask = cv2.GaussianBlur(mask, (5, 5), 0)

    out = arr.copy()
    out[:, :, 3] = np.minimum(out[:, :, 3], mask)
    return Image.fromarray(out, "RGBA")


def main():
    src = Image.open(SRC).convert("RGBA")
    square = to_square_canvas(src)
    side = square.size[0]
    print(f"Square canvas: {side}x{side}")

    # 1024로 업스케일 (모바일 화면 대응)
    target = 1024
    square_hd = square.resize((target, target), Image.LANCZOS)

    for name, (lo, hi) in COLOR_RANGES.items():
        piece = extract_by_color(square_hd, lo, hi)
        out_path = os.path.join(OUT_DIR, f"splash_piece_{name}.png")
        piece.save(out_path, "PNG")
        print(f"Saved: {out_path}")


if __name__ == "__main__":
    main()
