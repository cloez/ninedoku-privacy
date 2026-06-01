"""
Ninedoku Google Play Store 등록 콘텐츠 가이드 — PDF 생성기
reportlab 기반, 한국어 지원 (맑은고딕)
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')

from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, KeepTogether, Image as RLImage
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY

# === 경로 ===
OUT_DIR = Path(r"D:\00. Workspace\sudoku\tools\store_assets")
OUT_PDF = OUT_DIR / "Ninedoku_PlayStore_Guide.pdf"
ICON_PATH = OUT_DIR / "app_icon_512.png"
FEATURE_PATH = OUT_DIR / "feature_graphic_1024x500.png"
SS_DIR = OUT_DIR / "screenshots"

# === 폰트 등록 ===
pdfmetrics.registerFont(TTFont('Malgun', 'C:/Windows/Fonts/malgun.ttf'))
pdfmetrics.registerFont(TTFont('MalgunBd', 'C:/Windows/Fonts/malgunbd.ttf'))

# === 색상 ===
C_PRIMARY = HexColor('#4A90D9')
C_DARK = HexColor('#0F0F19')
C_ACCENT = HexColor('#3B7DD8')
C_LIGHT_BG = HexColor('#F0F4FA')
C_TEXT = HexColor('#222222')
C_SUB = HexColor('#555555')
C_GUIDE = HexColor('#1B5E20')
C_WARN = HexColor('#E65100')
C_TABLE_HEAD = HexColor('#2C5282')
C_TABLE_STRIPE = HexColor('#EBF2FA')

# === 스타일 정의 ===
def make_styles():
    s = {}
    s['title'] = ParagraphStyle('Title', fontName='MalgunBd', fontSize=26,
                                leading=34, alignment=TA_CENTER, textColor=C_PRIMARY,
                                spaceAfter=4*mm)
    s['subtitle'] = ParagraphStyle('Subtitle', fontName='Malgun', fontSize=12,
                                   leading=16, alignment=TA_CENTER, textColor=C_SUB,
                                   spaceAfter=8*mm)
    s['h1'] = ParagraphStyle('H1', fontName='MalgunBd', fontSize=18, leading=24,
                             textColor=C_PRIMARY, spaceBefore=10*mm, spaceAfter=5*mm)
    s['h2'] = ParagraphStyle('H2', fontName='MalgunBd', fontSize=14, leading=19,
                             textColor=C_ACCENT, spaceBefore=7*mm, spaceAfter=3*mm)
    s['h3'] = ParagraphStyle('H3', fontName='MalgunBd', fontSize=12, leading=16,
                             textColor=C_TEXT, spaceBefore=5*mm, spaceAfter=2*mm)
    s['body'] = ParagraphStyle('Body', fontName='Malgun', fontSize=10, leading=15,
                               textColor=C_TEXT, spaceAfter=2*mm, alignment=TA_JUSTIFY)
    s['body_center'] = ParagraphStyle('BodyCenter', fontName='Malgun', fontSize=10,
                                      leading=15, textColor=C_TEXT, alignment=TA_CENTER)
    s['bullet'] = ParagraphStyle('Bullet', fontName='Malgun', fontSize=10, leading=15,
                                 textColor=C_TEXT, leftIndent=12*mm, bulletIndent=5*mm,
                                 spaceAfter=1.5*mm)
    s['guide'] = ParagraphStyle('Guide', fontName='Malgun', fontSize=9.5, leading=14,
                                textColor=C_GUIDE, leftIndent=8*mm, spaceAfter=2*mm,
                                backColor=HexColor('#E8F5E9'), borderPadding=4)
    s['warn'] = ParagraphStyle('Warn', fontName='MalgunBd', fontSize=9.5, leading=14,
                               textColor=C_WARN, leftIndent=8*mm, spaceAfter=2*mm)
    s['code'] = ParagraphStyle('Code', fontName='Malgun', fontSize=9, leading=13,
                               textColor=HexColor('#333333'), backColor=HexColor('#F5F5F5'),
                               leftIndent=6*mm, rightIndent=6*mm, spaceAfter=3*mm,
                               borderPadding=6)
    s['small'] = ParagraphStyle('Small', fontName='Malgun', fontSize=8.5, leading=12,
                                textColor=C_SUB, spaceAfter=1*mm)
    s['toc'] = ParagraphStyle('TOC', fontName='Malgun', fontSize=11, leading=18,
                              textColor=C_ACCENT, leftIndent=8*mm, spaceAfter=1.5*mm)
    return s

ST = make_styles()


# === 유틸리티 ===
def p(text, style='body'):
    return Paragraph(text, ST[style])

def h1(text):
    return Paragraph(text, ST['h1'])

def h2(text):
    return Paragraph(text, ST['h2'])

def h3(text):
    return Paragraph(text, ST['h3'])

def bullet(text):
    return Paragraph(f'• {text}', ST['bullet'])

def guide(text):
    return Paragraph(f'💡 {text}', ST['guide'])

def warn(text):
    return Paragraph(f'⚠ {text}', ST['warn'])

def spacer(h=3):
    return Spacer(1, h*mm)

def hr():
    return HRFlowable(width="100%", thickness=0.5, color=HexColor('#CCCCCC'),
                       spaceAfter=3*mm, spaceBefore=3*mm)


def make_table(headers, rows, col_widths=None):
    """표 생성"""
    header_paras = [Paragraph(f'<b>{h}</b>', ParagraphStyle('TH', fontName='MalgunBd',
                    fontSize=9, leading=12, textColor=white, alignment=TA_CENTER))
                    for h in headers]
    data = [header_paras]
    for row in rows:
        data.append([Paragraph(str(c), ParagraphStyle('TD', fontName='Malgun',
                     fontSize=9, leading=13, textColor=C_TEXT)) for c in row])

    t = Table(data, colWidths=col_widths, repeatRows=1)
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), C_TABLE_HEAD),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#CCCCCC')),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]
    # 줄무늬
    for i in range(1, len(data)):
        if i % 2 == 0:
            style_cmds.append(('BACKGROUND', (0, i), (-1, i), C_TABLE_STRIPE))

    t.setStyle(TableStyle(style_cmds))
    return t


# === 페이지 헤더/푸터 ===
def header_footer(canvas, doc):
    canvas.saveState()
    # 헤더 라인
    canvas.setStrokeColor(C_PRIMARY)
    canvas.setLineWidth(1.5)
    canvas.line(20*mm, A4[1] - 12*mm, A4[0] - 20*mm, A4[1] - 12*mm)
    canvas.setFont('Malgun', 8)
    canvas.setFillColor(C_SUB)
    canvas.drawString(20*mm, A4[1] - 11*mm, "Ninedoku — Google Play Store 등록 가이드")
    # 푸터
    canvas.setFont('Malgun', 8)
    canvas.setFillColor(C_SUB)
    canvas.drawCentredString(A4[0] / 2, 10*mm, f"— {doc.page} —")
    canvas.drawRightString(A4[0] - 20*mm, 10*mm, "2026-05-27")
    canvas.restoreState()


# === 문서 본문 ===
def build_content():
    story = []
    W = A4[0] - 40*mm  # 사용 가능 너비

    # ===== 표지 =====
    story.append(Spacer(1, 30*mm))

    # 앱 아이콘
    if ICON_PATH.exists():
        story.append(RLImage(str(ICON_PATH), width=35*mm, height=35*mm, hAlign='CENTER'))
        story.append(spacer(5))

    story.append(p('Ninedoku', 'title'))
    story.append(p('Google Play Store 등록 콘텐츠 가이드', 'subtitle'))
    story.append(hr())
    story.append(spacer(5))
    story.append(p('커머스 &amp; 마케팅 전문가 관점의 Play Store 최적화(ASO) 가이드', 'body_center'))
    story.append(spacer(5))

    # 그래픽 이미지 미리보기
    if FEATURE_PATH.exists():
        story.append(RLImage(str(FEATURE_PATH), width=W, height=W * 500/1024, hAlign='CENTER'))
        story.append(spacer(3))
        story.append(p('▲ Feature Graphic (1024×500)', 'small'))

    story.append(spacer(10))

    # 메타 정보 테이블
    meta_data = [
        ['앱 이름', 'Ninedoku'],
        ['패키지', 'com.cloez.sudoku'],
        ['버전', '1.0.0+1'],
        ['대상 플랫폼', 'Android 12+ (minSdk 31)'],
        ['지원 언어', '한국어, English, 日本語, 中文'],
        ['프로모션 영상', 'https://youtube.com/shorts/p2Ft5_2Xs9s'],
        ['프라이버시 정책', 'https://cloez.github.io/ninedoku-privacy/'],
        ['연락처', 'shinhandscloud26@gmail.com'],
    ]
    meta_table = Table(
        [[Paragraph(f'<b>{r[0]}</b>', ParagraphStyle('', fontName='MalgunBd', fontSize=9, leading=13, textColor=C_TEXT)),
          Paragraph(r[1], ParagraphStyle('', fontName='Malgun', fontSize=9, leading=13, textColor=C_TEXT))]
         for r in meta_data],
        colWidths=[35*mm, W - 35*mm]
    )
    meta_table.setStyle(TableStyle([
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#DDDDDD')),
        ('BACKGROUND', (0, 0), (0, -1), C_LIGHT_BG),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(meta_table)

    story.append(PageBreak())

    # ===== 목차 =====
    story.append(p('📋 목차', 'h1'))
    story.append(hr())
    toc_items = [
        '1. 스토어 등록정보 (Store Listing)',
        '   1-1. 앱 이름  |  1-2. 간단한 설명  |  1-3. 자세한 설명',
        '2. 그래픽 에셋 (Graphic Assets)',
        '   2-1. 앱 아이콘  |  2-2. 그래픽 이미지  |  2-3. 스크린샷  |  2-4. 동영상',
        '3. 분류 및 연락처',
        '4. 콘텐츠 등급 (Content Rating)',
        '5. 데이터 안전 (Data Safety)',
        '6. 다국어 등록',
        '7. 출시 전 체크리스트',
        '8. ASO 키워드 전략',
        '9. 프라이버시 정책',
    ]
    for item in toc_items:
        story.append(p(item, 'toc'))
    story.append(PageBreak())

    # ========================================
    # 1. 스토어 등록정보
    # ========================================
    story.append(h1('1. 스토어 등록정보 (Store Listing)'))
    story.append(hr())

    # 1-1. 앱 이름
    story.append(h2('1-1. 앱 이름 (App Name)'))
    story.append(p('제한: 최대 30자 | ASO 전략: 브랜드명 + 핵심 키워드 조합'))
    story.append(make_table(
        ['언어', '앱 이름'],
        [
            ['🇰🇷 한국어', 'Ninedoku - 오프라인 스도쿠'],
            ['🇺🇸 영어', 'Ninedoku - Offline Sudoku'],
            ['🇯🇵 일본어', 'Ninedoku - オフライン数独'],
            ['🇨🇳 중국어', 'Ninedoku - 离线数独'],
        ],
        [30*mm, W - 30*mm]
    ))
    story.append(spacer(3))
    story.append(guide('Play Console → 스토어 등록정보 → 기본 스토어 등록정보 → "앱 이름"에 입력'))
    story.append(bullet('"Ninedoku"만 쓰면 검색 노출이 약합니다 — "스도쿠"/"Sudoku" 키워드 필수 포함'))
    story.append(bullet('하이픈(-)으로 브랜드와 키워드를 자연스럽게 연결'))

    # 1-2. 간단한 설명
    story.append(h2('1-2. 간단한 설명 (Short Description)'))
    story.append(p('제한: 최대 80자 | 역할: 검색 결과와 스토어 상단에 노출되는 첫인상 문구'))
    story.append(make_table(
        ['언어', '간단한 설명'],
        [
            ['🇰🇷 한국어', '광고 없는 순수 스도쿠. 인터넷 없이 언제 어디서든. 매일 새로운 퍼즐에 도전하세요!'],
            ['🇺🇸 영어', 'Pure Sudoku, no ads. Play offline anytime. Challenge a new puzzle every day!'],
            ['🇯🇵 일본어', '広告なしの純粋な数独。オフラインでいつでもどこでも。毎日新しいパズルに挑戦！'],
            ['🇨🇳 중국어', '无广告纯净数独。无需网络随时随地畅玩。每天挑战全新谜题！'],
        ],
        [30*mm, W - 30*mm]
    ))
    story.append(spacer(3))
    story.append(guide('Play Console → 스토어 등록정보 → "간단한 설명"에 입력'))
    story.append(bullet('첫 40자가 가장 중요 (검색 결과에서 잘리는 지점)'))
    story.append(bullet('"광고 없는" + "오프라인" = 2대 차별 포인트를 앞에 배치'))

    # 1-3. 자세한 설명
    story.append(h2('1-3. 자세한 설명 (Full Description)'))
    story.append(p('제한: 최대 4,000자 | 역할: 앱의 모든 가치를 전달하는 본문'))
    story.append(p('구조: <b>후크 → 핵심 기능 → 상세 기능 → 신뢰 요소 → CTA</b>'))
    story.append(spacer(3))

    # 한국어 설명
    story.append(h3('🇰🇷 한국어 (기본 언어)'))
    ko_desc = """순수한 스도쿠의 즐거움, Ninedoku

광고도, 인터넷도, 개인정보 수집도 없습니다.
비행기 안에서도, 지하철에서도, 캠핑장에서도 — 언제 어디서든 스도쿠를 즐기세요.

Ninedoku는 스도쿠 본연의 재미에만 집중한 오프라인 퍼즐 게임입니다.

▶ 왜 Ninedoku인가요?
• 완전 오프라인 — 인터넷 권한 자체가 없는 앱. 데이터 걱정 제로
• 광고 없음 — 배너도, 전면 광고도, 보상형 광고도 없습니다
• 개인정보 보호 — 어떤 데이터도 수집하지 않습니다
• 가벼운 용량 — 50MB 이하의 깔끔한 앱

▶ 다양한 게임 모드
• 클래식 — 전통 스도쿠를 6단계 난이도로 즐기세요
• 오늘의 퍼즐 — 매일 새로운 퍼즐이 자동 생성됩니다
• 릴렉스 — 시간 제한 없이 여유롭게 풀어보세요

▶ 6단계 난이도
입문부터 마스터까지 6단계 난이도를 제공합니다.

▶ 스마트 기능
• 메모 모드 — 후보 숫자를 자유롭게 기록
• 자동 메모 제거 — 정답 입력 시 관련 메모 자동 정리
• 되돌리기 — 실수해도 걱정 없이 되돌리기
• 힌트 — 막힐 때 단계별 힌트 지원
• 자동 완성 — 거의 다 풀었을 때 자동으로 채워줍니다
• 이어하기 — 중단한 게임을 언제든 이어서 플레이

▶ 성장하는 재미
• 상세 통계, 배지 수집, 월간 캘린더

▶ 맞춤 설정
• 라이트/다크 테마, 텍스트 크기 조절, 사운드 및 진동 설정

지금 Ninedoku를 다운로드하고, 순수한 스도쿠의 즐거움을 경험하세요."""

    for line in ko_desc.split('\n'):
        line = line.strip()
        if not line:
            story.append(spacer(2))
        elif line.startswith('▶'):
            story.append(Paragraph(f'<b>{line}</b>', ST['body']))
        elif line.startswith('•'):
            story.append(bullet(line[2:]))
        else:
            story.append(p(line))

    story.append(spacer(5))

    # 영어 설명
    story.append(h3('🇺🇸 영어'))
    en_desc = """Pure Sudoku joy — Ninedoku

No ads. No internet. No data collection.
On a plane, on a subway, at a campsite — enjoy Sudoku anytime, anywhere.

Ninedoku is an offline puzzle game focused purely on the joy of Sudoku.

▶ Why Ninedoku?
• Fully offline — no internet permission at all. Zero data worries
• No ads — no banners, no interstitials, no rewarded ads
• Privacy first — we collect absolutely no personal data
• Lightweight — a clean app under 50MB

▶ Multiple Game Modes
• Classic — traditional Sudoku with 6 difficulty levels
• Daily Puzzle — a new puzzle generated automatically every day
• Relax — solve at your own pace with no time pressure

▶ 6 Difficulty Levels — from Beginner to Master

▶ Smart Features
• Memo mode, Auto memo cleanup, Undo, Hints
• Auto-complete, Resume

▶ Track Your Growth — Detailed stats, Badge collection, Monthly calendar

▶ Personalize — Light/Dark theme, Text size adjustment, Sound settings

Download Ninedoku now and experience the pure joy of Sudoku."""

    for line in en_desc.split('\n'):
        line = line.strip()
        if not line:
            story.append(spacer(2))
        elif line.startswith('▶'):
            story.append(Paragraph(f'<b>{line}</b>', ST['body']))
        elif line.startswith('•'):
            story.append(bullet(line[2:]))
        else:
            story.append(p(line))

    story.append(spacer(5))

    # 일본어/중국어 요약
    story.append(h3('🇯🇵 일본어 / 🇨🇳 중국어'))
    story.append(p('일본어와 중국어 설명은 한국어/영어 구조를 동일하게 번역한 버전입니다. 핵심 키워드(数独/오프라인/広告なし/无广告)를 자연스럽게 반복 배치합니다.'))
    story.append(guide('Play Console → 스토어 등록정보 → "자세한 설명"에 각 언어별로 입력'))
    story.append(bullet('첫 3줄이 생명 — "더보기" 전에 보이는 부분에 핵심 차별점 배치'))
    story.append(bullet('유니코드 기호(▶, •) 사용으로 시각적 구조화 — 가독성 향상'))
    story.append(bullet('CTA("지금 다운로드하세요")로 마무리하여 행동 유도'))

    story.append(PageBreak())

    # ========================================
    # 2. 그래픽 에셋
    # ========================================
    story.append(h1('2. 그래픽 에셋 (Graphic Assets)'))
    story.append(hr())

    # 2-1. 앱 아이콘
    story.append(h2('2-1. 앱 아이콘 (App Icon)'))
    story.append(p('규격: <b>512 × 512 px</b>, PNG (32비트) | 용량: 최대 1MB'))
    if ICON_PATH.exists():
        story.append(RLImage(str(ICON_PATH), width=30*mm, height=30*mm, hAlign='CENTER'))
        story.append(p('▲ 생성된 앱 아이콘 (512×512)', 'small'))
    story.append(guide('Play Console → 스토어 등록정보 → 그래픽 → "앱 아이콘"에 업로드'))
    story.append(bullet('둥근 모서리 마스킹은 Play Store가 자동 적용 — 정사각형으로 업로드'))
    story.append(p(f'<b>파일:</b> store_assets/app_icon_512.png'))

    # 2-2. 그래픽 이미지
    story.append(h2('2-2. 그래픽 이미지 (Feature Graphic)'))
    story.append(p('규격: <b>1024 × 500 px</b>, PNG 또는 JPEG | 용도: 스토어 상단 배너'))
    if FEATURE_PATH.exists():
        story.append(RLImage(str(FEATURE_PATH), width=W, height=W*500/1024, hAlign='CENTER'))
        story.append(p('▲ 생성된 그래픽 이미지 (1024×500)', 'small'))
    story.append(guide('Play Console → 스토어 등록정보 → 그래픽 → "그래픽 이미지"에 업로드'))
    story.append(warn('필수 항목! 없으면 추천/피처링 대상에서 제외됩니다'))
    story.append(p(f'<b>파일:</b> store_assets/feature_graphic_1024x500.png'))

    # 2-3. 스크린샷
    story.append(h2('2-3. 스크린샷 (Screenshots)'))
    story.append(p('규격: <b>1080 × 1920 px</b> (세로 FHD) | 수량: 최소 2장, 최대 8장 (8장 권장)'))
    story.append(spacer(3))

    story.append(make_table(
        ['순서', '파일명', '캡션', '내용'],
        [
            ['1', '01_06_home.png', '깔끔한 홈 화면', '한눈에 보는 모든 기능'],
            ['2', '02_05_gameplay.png', '직관적인 플레이', '터치 한 번으로 숫자 입력'],
            ['3', '03_07_gamemode.png', '3가지 게임 모드', '클래식 · 릴렉스 · 오늘의 퍼즐'],
            ['4', '04_10_selectlevel.png', '6단계 난이도', '초보부터 고수까지'],
            ['5', '05_04_completion.png', '달성의 쾌감', '게임 완료 &amp; 배지 획득'],
            ['6', '06_11_today.png', '매일 새로운 도전', '오늘의 퍼즐로 꾸준히'],
            ['7', '07_03_statistics.png', '나의 성장 기록', '상세한 통계로 실력 확인'],
            ['8', '08_02_badges.png', '배지 수집', '도전 과제 달성의 재미'],
        ],
        [12*mm, 42*mm, 35*mm, W - 89*mm]
    ))

    story.append(spacer(3))

    # 스크린샷 미리보기 (2열)
    ss_files = sorted(SS_DIR.glob('*.png'))
    if ss_files:
        # 4행 2열로 배치
        for i in range(0, len(ss_files), 2):
            row_imgs = []
            for j in range(2):
                if i + j < len(ss_files):
                    img_path = ss_files[i + j]
                    cell_w = W / 2 - 5*mm
                    cell_h = cell_w * 1920 / 1080
                    row_imgs.append(RLImage(str(img_path), width=cell_w, height=cell_h))
                else:
                    row_imgs.append('')

            t = Table([row_imgs], colWidths=[W/2, W/2])
            t.setStyle(TableStyle([
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ]))
            story.append(t)
            story.append(spacer(3))

    story.append(guide('Play Console → 스토어 등록정보 → 그래픽 → "스크린샷"에서 번호 순서대로 업로드'))
    story.append(p(f'<b>폴더:</b> store_assets/screenshots/'))

    # 2-4. 동영상
    story.append(h2('2-4. 프로모션 동영상'))
    story.append(p('형식: YouTube URL (공개 또는 일부 공개)'))
    story.append(p('<b>URL:</b> https://youtube.com/shorts/p2Ft5_2Xs9s?feature=share'))
    story.append(guide('Play Console → 스토어 등록정보 → 그래픽 → "동영상"에 URL 붙여넣기'))
    story.append(warn('동영상은 반드시 "공개" 또는 "일부 공개"여야 합니다 (비공개 X)'))

    story.append(PageBreak())

    # ========================================
    # 3. 분류 및 연락처
    # ========================================
    story.append(h1('3. 분류 및 연락처'))
    story.append(hr())

    story.append(h2('3-1. 앱 유형 및 카테고리'))
    story.append(make_table(
        ['항목', '값', '설명'],
        [
            ['앱 유형', '게임', '"앱" vs "게임" 중 선택'],
            ['카테고리', '퍼즐 (Puzzle)', '게임 → 퍼즐이 정확한 매칭'],
            ['태그', '스도쿠, 퍼즐, 두뇌, 오프라인', '최대 5개 선택 가능'],
        ],
        [25*mm, 40*mm, W - 65*mm]
    ))
    story.append(guide('Play Console → 앱 콘텐츠 → "앱 카테고리"에서 설정'))

    story.append(h2('3-2. 연락처 정보'))
    story.append(make_table(
        ['항목', '값', '필수'],
        [
            ['이메일', 'shinhandscloud26@gmail.com', '✅ 필수'],
            ['전화번호', '(선택사항)', '❌ 선택'],
            ['웹사이트', '(선택사항)', '❌ 선택'],
        ],
        [25*mm, W - 50*mm, 25*mm]
    ))
    story.append(guide('Play Console → 스토어 등록정보 → "연락처 세부정보"에 입력'))

    # ========================================
    # 4. 콘텐츠 등급
    # ========================================
    story.append(h1('4. 콘텐츠 등급 (Content Rating)'))
    story.append(hr())
    story.append(p('IARC 설문지에서 모든 항목에 <b>"아니요"</b>를 선택합니다.'))
    story.append(spacer(3))

    story.append(make_table(
        ['질문', '답변', '이유'],
        [
            ['폭력성', '아니요', '폭력 없음'],
            ['성적 콘텐츠', '아니요', '해당 없음'],
            ['언어', '아니요', '욕설/비속어 없음'],
            ['규제 물질', '아니요', '해당 없음'],
            ['도박', '아니요', '도박 요소 없음'],
            ['사용자 생성 콘텐츠', '아니요', 'UGC 없음'],
            ['사용자 간 상호작용', '아니요', '소셜 기능 없음'],
            ['위치 공유', '아니요', '위치 수집 없음'],
            ['구매', '아니요', '인앱 결제 없음'],
        ],
        [45*mm, 20*mm, W - 65*mm]
    ))
    story.append(spacer(3))
    story.append(p('<b>예상 결과:</b> 전체이용가 (PEGI 3 / Everyone) — 모든 연령 이용 가능'))
    story.append(guide('Play Console → 앱 콘텐츠 → "콘텐츠 등급" → "설문지 시작" 클릭'))

    # ========================================
    # 5. 데이터 안전
    # ========================================
    story.append(h1('5. 데이터 안전 (Data Safety)'))
    story.append(hr())
    story.append(p('Ninedoku의 <b>최대 마케팅 포인트</b>입니다. 모든 항목에서 "수집하지 않음"을 선택할 수 있습니다.'))
    story.append(spacer(3))

    story.append(make_table(
        ['질문', '답변'],
        [
            ['필수 사용자 데이터를 수집/공유하나요?', '아니요'],
            ['사용자 데이터를 다른 기업과 공유하나요?', '아니요'],
            ['사용자 데이터를 수집하나요?', '아니요'],
            ['계정 삭제 방법을 제공하나요?', '해당 없음 (계정 자체가 없음)'],
        ],
        [W * 0.65, W * 0.35]
    ))
    story.append(spacer(3))
    story.append(p('<b>스토어에 표시될 배지:</b>'))
    story.append(bullet('🛡️ 데이터가 제3자와 공유되지 않음'))
    story.append(bullet('🛡️ 데이터가 수집되지 않음'))
    story.append(spacer(2))
    story.append(p('대부분의 경쟁 스도쿠 앱은 광고 SDK로 인해 이 배지를 받지 못합니다.'))
    story.append(guide('Play Console → 앱 콘텐츠 → "데이터 안전" → "시작" 클릭'))

    # ========================================
    # 6. 다국어 등록
    # ========================================
    story.append(h1('6. 다국어 등록'))
    story.append(hr())

    story.append(make_table(
        ['언어 코드', '언어', '우선순위'],
        [
            ['ko-KR', '한국어', '🔴 기본 언어'],
            ['en-US', '영어 (미국)', '🔴 필수 (글로벌 기본)'],
            ['ja-JP', '일본어', '🟡 권장'],
            ['zh-CN', '중국어 (간체)', '🟡 권장'],
        ],
        [30*mm, 40*mm, W - 70*mm]
    ))
    story.append(spacer(3))
    story.append(guide('Play Console → 스토어 등록정보 → "번역 관리" → "언어 추가"'))
    story.append(bullet('기본 언어(한국어)로 모든 필드를 먼저 완성'))
    story.append(bullet('각 언어별로 앱 이름, 간단한 설명, 자세한 설명을 각각 입력'))
    story.append(bullet('스크린샷은 우선 한국어 스크린샷을 공용으로 사용 (추후 언어별 별도 제작)'))

    story.append(PageBreak())

    # ========================================
    # 7. 출시 전 체크리스트
    # ========================================
    story.append(h1('7. 출시 전 체크리스트'))
    story.append(hr())

    story.append(h2('Play Console 필수 설정'))
    story.append(make_table(
        ['섹션', '항목', '설정값'],
        [
            ['앱 액세스', '특별한 액세스', '특별한 액세스 없음'],
            ['광고', '광고 포함 여부', '광고 포함하지 않음'],
            ['콘텐츠 등급', 'IARC 설문', '모두 "아니요" → 전체이용가'],
            ['타겟층', '대상 연령', '모든 연령'],
            ['뉴스 앱', '해당 여부', '뉴스 앱 아님'],
            ['데이터 안전', '설문 완료', '모두 "수집 안 함"'],
        ],
        [30*mm, 30*mm, W - 60*mm]
    ))

    story.append(h2('스토어 등록정보 완성도'))
    story.append(make_table(
        ['항목', '필수', '파일/내용'],
        [
            ['앱 이름', '✅', '위 1-1 참조'],
            ['간단한 설명', '✅', '위 1-2 참조'],
            ['자세한 설명', '✅', '위 1-3 참조'],
            ['앱 아이콘', '✅', 'store_assets/app_icon_512.png'],
            ['그래픽 이미지', '✅', 'store_assets/feature_graphic_1024x500.png'],
            ['스크린샷 (8장)', '✅', 'store_assets/screenshots/ 폴더'],
            ['프로모션 동영상', '❌ 선택', 'YouTube URL'],
        ],
        [35*mm, 15*mm, W - 50*mm]
    ))

    story.append(h2('가격 및 배포'))
    story.append(make_table(
        ['항목', '설정값', '비고'],
        [
            ['가격', '무료', '한 번 "무료" 설정 시 유료 변경 불가'],
            ['배포 국가', '모든 국가', '나중에 추가/제거 가능'],
            ['인앱 상품', '없음', ''],
        ],
        [25*mm, 30*mm, W - 55*mm]
    ))

    # ========================================
    # 8. ASO 키워드 전략
    # ========================================
    story.append(h1('8. ASO 키워드 전략'))
    story.append(hr())

    story.append(h2('검색 키워드'))
    story.append(make_table(
        ['우선순위', '한국어', '영어'],
        [
            ['🔴 최상', '스도쿠, 오프라인 스도쿠', 'sudoku, offline sudoku'],
            ['🔴 최상', '광고없는 스도쿠', 'sudoku no ads'],
            ['🟡 높음', '무료 스도쿠, 퍼즐 게임', 'free sudoku, puzzle game'],
            ['🟡 높음', '두뇌 게임, 숫자 퍼즐', 'brain game, number puzzle'],
            ['🟢 보통', '매일 퍼즐, 수도쿠', 'daily puzzle, sudoku offline'],
        ],
        [25*mm, (W - 25*mm) / 2, (W - 25*mm) / 2]
    ))

    story.append(h2('경쟁 차별화 포인트'))
    story.append(make_table(
        ['차별점', 'Ninedoku', '대부분의 경쟁 앱'],
        [
            ['광고', '❌ 없음', '✅ 전면광고, 배너'],
            ['인터넷', '❌ 권한 자체 없음', '✅ 필수'],
            ['개인정보', '❌ 수집 없음', '✅ 광고 SDK 데이터'],
            ['인앱결제', '❌ 없음', '✅ 힌트/광고제거 유료'],
            ['용량', '~50MB', '100~200MB'],
        ],
        [25*mm, (W - 25*mm) / 2, (W - 25*mm) / 2]
    ))

    # ========================================
    # 9. 프라이버시 정책
    # ========================================
    story.append(h1('9. 프라이버시 정책'))
    story.append(hr())
    story.append(p('<b>URL:</b> https://cloez.github.io/ninedoku-privacy/'))
    story.append(spacer(2))
    story.append(p('GitHub Pages에 호스팅된 프라이버시 정책 페이지입니다. 4개 언어(영어, 한국어, 일본어, 중국어)를 지원합니다.'))
    story.append(spacer(3))
    story.append(guide('Play Console → 앱 콘텐츠 → "개인정보처리방침" → URL 입력'))
    story.append(warn('데이터를 수집하지 않아도 프라이버시 정책 URL은 필수입니다'))

    story.append(spacer(10))

    # 출시 후 로드맵
    story.append(h2('출시 후 최적화 로드맵'))
    story.append(make_table(
        ['시점', '작업', '목적'],
        [
            ['출시 즉시', '가족/지인에게 리뷰 요청 (5개+)', '초기 평점 확보 (4.5+ 목표)'],
            ['1주 후', '스크린샷 A/B 테스트 시작', '전환율 최적화'],
            ['2주 후', '리뷰 답변 시작', '사용자 신뢰 구축'],
            ['1개월 후', '설명 키워드 조정', 'ASO 키워드 최적화'],
            ['2개월 후', '영어/일본어 스크린샷 별도 제작', '글로벌 전환율 향상'],
        ],
        [25*mm, (W - 25*mm) / 2, (W - 25*mm) / 2]
    ))

    story.append(spacer(15))
    story.append(hr())
    story.append(p('<b>당장 시작하려면 이 순서로:</b>', 'body_center'))
    story.append(spacer(2))
    story.append(bullet('1. 프라이버시 정책 URL 확인 (GitHub Pages)'))
    story.append(bullet('2. Play Console에서 위 내용 순서대로 입력'))
    story.append(bullet('3. 그래픽 에셋(아이콘, 그래픽 이미지, 스크린샷) 업로드'))
    story.append(bullet('4. AAB/APK 파일 업로드 후 검토 제출'))

    return story


# === 메인 ===
def main():
    print("=" * 50)
    print("  Play Store 가이드 PDF 생성")
    print("=" * 50)

    doc = SimpleDocTemplate(
        str(OUT_PDF),
        pagesize=A4,
        topMargin=18*mm,
        bottomMargin=18*mm,
        leftMargin=20*mm,
        rightMargin=20*mm,
        title="Ninedoku - Google Play Store 등록 가이드",
        author="Ninedoku Team",
    )

    story = build_content()
    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)

    size_mb = OUT_PDF.stat().st_size / 1024 / 1024
    print(f"\n  PDF 생성 완료!")
    print(f"  파일: {OUT_PDF}")
    print(f"  크기: {size_mb:.1f} MB")
    print("=" * 50)


if __name__ == '__main__':
    main()
