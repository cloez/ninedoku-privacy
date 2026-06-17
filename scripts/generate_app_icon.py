"""K-Puzzles 앱 아이콘 생성 스크립트.

출력:
- assets/app_icon.png            : 1024x1024 (마크 + 배경, 런처/스토어용)
- assets/app_icon_foreground.png : 1024x1024 (마크만, 투명 배경, adaptive icon용)
- assets/app_icon_monochrome.png : 1024x1024 (단색 흰색, themed icon용)

디자인:
- 진한 네이비 배경 (#122B5E) 둥근 사각
- K 글자 모양으로 4개 캡슐 배치
  - 좌측 막대: 파랑(위) + 보라(아래) 세로 캡슐, 거의 붙음
  - 우측 위: 주황 대각 캡슐 — 발이 좌측 막대 중앙에서 출발해 우상으로
  - 우측 아래: 초록 대각 캡슐 — 머리가 좌측 막대 중앙에서 출발해 우하로
"""
from PIL import Image, ImageDraw

W = 1024
NAVY = (18, 43, 94, 255)
BLUE = (63, 179, 232, 255)
ORANGE = (249, 168, 37, 255)
PURPLE = (126, 34, 206, 255)
GREEN = (46, 176, 90, 255)
BG_RADIUS = 224  # 둥근 사각 모서리


def make_capsule(width: int, height: int, color):
    """캡슐형(양 끝이 반원) 이미지 생성"""
    cap = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(cap)
    radius = width // 2
    cdraw.rounded_rectangle((0, 0, width, height), radius=radius, fill=color)
    return cap


def paste_rotated_centered(base, capsule_img, angle_deg, center_xy):
    """캡슐을 회전시켜 base의 (cx, cy) 위치를 중심으로 합성"""
    rotated = capsule_img.rotate(angle_deg, resample=Image.BICUBIC, expand=True)
    cx, cy = center_xy
    x = cx - rotated.width // 2
    y = cy - rotated.height // 2
    base.alpha_composite(rotated, (x, y))


def compose_mark(fg_color_override=None):
    """K 마크만 그린 RGBA 이미지 반환 (배경 투명)"""
    mark = Image.new("RGBA", (W, W), (0, 0, 0, 0))

    # 색상 설정
    blue_col = fg_color_override or BLUE
    purple_col = fg_color_override or PURPLE
    orange_col = fg_color_override or ORANGE
    green_col = fg_color_override or GREEN

    # 좌측 세로 막대 — 위(파랑) + 아래(보라). 둘이 거의 붙어서 하나의 막대처럼 보이게.
    # 캡슐 크기: 너비 175, 높이 360
    LEFT_W, LEFT_H = 175, 360
    LEFT_X = 240  # 좌측 막대 시작 x

    # 1) 좌측 위 — 파랑 (y=140~500)
    blue_cap = make_capsule(LEFT_W, LEFT_H, blue_col)
    mark.alpha_composite(blue_cap, (LEFT_X, 140))

    # 2) 좌측 아래 — 보라 (y=508~868)
    purple_cap = make_capsule(LEFT_W, LEFT_H, purple_col)
    mark.alpha_composite(purple_cap, (LEFT_X, 508))

    # 좌측 막대 중심 좌표
    left_center_x = LEFT_X + LEFT_W // 2  # 327
    mid_y = 504  # 두 캡슐 사이 가운데

    # 우측 대각 캡슐 크기 (좀 더 길게)
    DIAG_W, DIAG_H = 175, 480

    # 3) 우측 위 — 주황 대각 (K의 위 사선 /)
    # 발(아래쪽 끝)이 좌측 막대 중심 근처에서 출발 → 머리(위쪽 끝)가 우상으로
    # 회전 양수(반시계, 화면상)로 머리가 우상단으로 향함
    orange_cap = make_capsule(DIAG_W, DIAG_H, orange_col)
    # 중심 위치를 조정: 캡슐의 한쪽 끝이 좌측 막대 가운데에 닿도록
    # 회전 각도 52도 → 캡슐 반길이(240)의 sin/cos만큼 이동
    import math
    angle_up = 52
    rad = math.radians(angle_up)
    # 머리는 (sin*240, -cos*240)만큼 중심에서 이동
    # 발은 (-sin*240, +cos*240). 발 위치를 (430, 500)로 두려면:
    # center = 발 + (sin*240, -cos*240) = (430 + sin52*240, 500 - cos52*240)
    foot_x, foot_y = 430, 500
    cx_up = foot_x + math.sin(rad) * (DIAG_H / 2)
    cy_up = foot_y - math.cos(rad) * (DIAG_H / 2)
    paste_rotated_centered(mark, orange_cap, angle_up, (int(cx_up), int(cy_up)))

    # 4) 우측 아래 — 초록 대각 (K의 아래 사선 \)
    # 머리(위쪽 끝)가 좌측 막대 중심 근처 → 발(아래쪽 끝)이 우하로
    # 회전 음수(시계, 화면상)로 머리가 좌상으로... 아니, 우리는 머리를 좌측 막대(좌상)에 두고
    # 발을 우하로 보내야 함. 회전 부호 = -52도
    green_cap = make_capsule(DIAG_W, DIAG_H, green_col)
    angle_dn = -52
    rad = math.radians(angle_dn)
    # 머리 위치를 (430, 508)로:
    # center = 머리 - (sin*240, -cos*240) = 머리 + (-sin*240, +cos*240)
    head_x, head_y = 430, 508
    cx_dn = head_x - math.sin(rad) * (DIAG_H / 2)
    cy_dn = head_y + math.cos(rad) * (DIAG_H / 2)
    paste_rotated_centered(mark, green_cap, angle_dn, (int(cx_dn), int(cy_dn)))

    return mark


def make_full_icon():
    """배경 + 마크 합성 (런처/스토어용)"""
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((0, 0, W, W), radius=BG_RADIUS, fill=NAVY)
    img.alpha_composite(compose_mark())
    return img


def make_foreground():
    """adaptive icon foreground — 마크만, 중심 75% 안전 영역에 들어가도록 축소"""
    mark = compose_mark()
    scale = 0.78
    new_size = int(W * scale)
    mark_small = mark.resize((new_size, new_size), Image.LANCZOS)
    fg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    offset = (W - new_size) // 2
    fg.alpha_composite(mark_small, (offset, offset))
    return fg


def make_monochrome():
    """themed icon용 단색(흰색) 마크"""
    mono = compose_mark(fg_color_override=(255, 255, 255, 255))
    scale = 0.78
    new_size = int(W * scale)
    mono_small = mono.resize((new_size, new_size), Image.LANCZOS)
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    offset = (W - new_size) // 2
    out.alpha_composite(mono_small, (offset, offset))
    return out


if __name__ == "__main__":
    import os
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets")
    out_dir = os.path.normpath(out_dir)

    full = make_full_icon()
    full.save(os.path.join(out_dir, "app_icon.png"), "PNG")

    fg = make_foreground()
    fg.save(os.path.join(out_dir, "app_icon_foreground.png"), "PNG")

    mono = make_monochrome()
    mono.save(os.path.join(out_dir, "app_icon_monochrome.png"), "PNG")

    print(f"Saved 3 icons to {out_dir}")
