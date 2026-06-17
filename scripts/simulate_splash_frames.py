"""SplashScreen 로직을 그대로 Python으로 시뮬레이션하여 핵심 프레임 렌더링.

목적: 그래픽 전문가 피드백을 위한 시각 자산.
출력: tmp/splash_sim/frame_{t}.png (6장)
"""
import os
import math
import numpy as np
from PIL import Image

OUT_DIR = "tmp/splash_sim"
CANVAS_W = 720
CANVAS_H = 1280
MARK_SIZE = 600  # 원본 큰 사이즈로 작업 후 resize

# Flutter SplashScreen과 동일 파라미터
PHASE_GATHER = 0.367
PHASE_HOLD = 0.633
FLY_DIST = 760


def ease_out_back(t, s=1.70158):
    return ((t - 1) ** 2) * ((s + 1) * (t - 1) + s) + 1


def ease_in_back(t, s=1.70158):
    return t * t * ((s + 1) * t - s)


def ease_out_cubic(t):
    return 1 - (1 - t) ** 3


def ease_in_cubic(t):
    return t ** 3


def ease_in_quad(t):
    return t * t


def piece_offset(away, t):
    if t < PHASE_GATHER:
        p = max(0.0, min(1.0, t / PHASE_GATHER))
        eased = ease_out_back(p)
        return (away[0] * (1 - eased), away[1] * (1 - eased))
    elif t < PHASE_HOLD:
        return (0, 0)
    else:
        p = max(0.0, min(1.0, (t - PHASE_HOLD) / (1.0 - PHASE_HOLD)))
        eased = ease_in_back(p)
        return (away[0] * eased, away[1] * eased)


def piece_rotation(start_rot, end_rot, t):
    if t < PHASE_GATHER:
        p = max(0.0, min(1.0, t / PHASE_GATHER))
        eased = ease_out_cubic(p)
        return start_rot * (1 - eased)
    elif t < PHASE_HOLD:
        return 0
    else:
        p = max(0.0, min(1.0, (t - PHASE_HOLD) / (1.0 - PHASE_HOLD)))
        eased = ease_in_cubic(p)
        return end_rot * eased


def mark_scale(t):
    if t < PHASE_GATHER:
        p = max(0.0, min(1.0, t / PHASE_GATHER))
        eased = ease_out_back(p)
        return 0.5 + 0.5 * eased
    elif t < PHASE_HOLD:
        p = (t - PHASE_GATHER) / (PHASE_HOLD - PHASE_GATHER)
        s = math.sin(p * math.pi)
        return 1.0 + 0.07 * s
    else:
        p = max(0.0, min(1.0, (t - PHASE_HOLD) / (1.0 - PHASE_HOLD)))
        return 1.0 + 0.20 * ease_in_quad(p)


def alpha(t):
    if t < 0.04:
        return max(0.0, min(1.0, t / 0.04))
    if t < PHASE_HOLD:
        return 1.0
    p = max(0.0, min(1.0, (t - PHASE_HOLD) / (1.0 - PHASE_HOLD)))
    return max(0.0, min(1.0, 1.0 - p * 0.95))


def compose_frame(t, pieces):
    """t 시점의 프레임 렌더링"""
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (18, 43, 94, 255))

    s = mark_scale(t)
    a = alpha(t)
    mark_size_scaled = int(MARK_SIZE * s)

    # 마크 캔버스 (확대된 크기)
    mark_canvas = Image.new("RGBA", (mark_size_scaled * 3, mark_size_scaled * 3), (0, 0, 0, 0))
    mark_center = mark_size_scaled * 3 // 2

    for name, away, start_rot, end_rot in pieces:
        src = Image.open(f"assets/splash_piece_{name}.png").convert("RGBA")
        # mark_size로 리사이즈
        src = src.resize((mark_size_scaled, mark_size_scaled), Image.LANCZOS)
        # 회전
        rot_deg = -math.degrees(piece_rotation(start_rot, end_rot, t))
        rotated = src.rotate(rot_deg, resample=Image.BICUBIC, expand=True)
        # 위치 (스케일과 동일 비율)
        ox, oy = piece_offset(away, t)
        ox = int(ox * s)
        oy = int(oy * s)
        # 캔버스 중심에 배치 + offset
        cx = mark_center + ox - rotated.width // 2
        cy = mark_center + oy - rotated.height // 2
        # 알파 적용
        if a < 1.0:
            r, g, b, alpha_ch = rotated.split()
            alpha_ch = alpha_ch.point(lambda x: int(x * a))
            rotated = Image.merge("RGBA", (r, g, b, alpha_ch))
        mark_canvas.alpha_composite(rotated, (cx, cy))

    # mark_canvas 중심을 canvas 중심에 합성
    paste_x = CANVAS_W // 2 - mark_canvas.width // 2
    paste_y = CANVAS_H // 2 - mark_canvas.height // 2
    canvas.alpha_composite(mark_canvas, (paste_x, paste_y))
    return canvas


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # Flutter 코드와 동일 파라미터
    pieces = [
        ("blue", (-FLY_DIST, -FLY_DIST * 0.85), -math.pi * 1.5, math.pi * 1.1),
        ("purple", (-FLY_DIST * 0.9, FLY_DIST), math.pi * 1.2, -math.pi * 1.3),
        ("orange", (FLY_DIST, -FLY_DIST), math.pi * 1.5, -math.pi * 1.1),
        ("green", (FLY_DIST, FLY_DIST * 0.85), -math.pi * 1.2, math.pi * 1.3),
    ]

    # 핵심 시점 (0~1 정규화)
    timestamps = [0.10, 0.25, 0.37, 0.50, 0.65, 0.85]
    for t in timestamps:
        frame = compose_frame(t, pieces)
        out_path = os.path.join(OUT_DIR, f"frame_t{int(t * 100):02d}.png")
        frame.save(out_path, "PNG")
        print(f"Saved: {out_path} (t={t * 3:.2f}s of 3s)")


if __name__ == "__main__":
    main()
