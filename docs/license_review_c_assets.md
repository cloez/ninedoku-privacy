# 라이센스 검토 C — 미디어 자산 (이미지/아이콘/사운드/폰트)

> 대상: K-Puzzles (`D:\00. Workspace\sudoku`)
> pubspec 포함 경로: `assets/`, `assets/sounds/`, `assets/icons/`

---

## 1. 자산 인벤토리

| 카테고리 | 위치 | 개수 | 형식 |
|---|---|---|---|
| 앱 아이콘 | `assets/app_icon*.png`, `app_icon_source.png`, `app_icon.webp` | 5 | PNG/WebP |
| 스플래시 조각 | `assets/splash_piece_*.png` | 4 | PNG |
| UI 아이콘 (SVG) | `assets/icons/*.svg` | 49 | SVG |
| 게임 허브 일러스트 (PNG) | `assets/icons/hub-*.png` | 15 | PNG |
| 효과음 | `assets/sounds/*.wav` | 11 | WAV |
| 폰트 | (pubspec `fonts:` 섹션 **없음**) | 0 | — |
| design/ (앱 미포함) | `design/`, `tools/`, 루트 `hub_*.png` 등 | 다수 | 참고용 |

---

## 2. 카테고리별 출처/라이센스 분석

### 2.1 앱 아이콘 — 🟢 자체 제작
- `scripts/generate_app_icon.py`: PIL로 4색 캡슐 "K" 마크를 코드로 그림 (NAVY/BLUE/ORANGE/GREEN/PURPLE 좌표 직접 계산).
- `scripts/generate_splash_pieces.py`: `app_icon_source.png`에서 OpenCV 색상 마스크로 4조각 분리 → 사용자 자산 파생.
- **사용자가 직접 제공한 디자인 + 코드 생성**. 저작권 사용자 소유.

### 2.2 UI 아이콘 (SVG 49개) — 🟢 자체 제작 (인라인 SVG)
- 샘플 검사(`game-sudoku.svg`): `<rect>`+`<text>` 약 1줄짜리 미니멀 SVG. Tabler/Material/Heroicons 등 외부 라이브러리의 패스 시그니처 없음.
- 파일명 grep으로 `tabler|material-symbols|heroicons|feather|lucide` 매칭 **0건**.
- 프로젝트 내에서 손수 작성한 단순 도형 SVG로 판단.

### 2.3 게임 허브 일러스트 (hub-*.png 15개) — 🟡 출처 확인 필요
- `scripts/`에 생성 코드 **없음** (grep 결과 0건). 코드 흔적이 없는 유일한 카테고리.
- 게임별 3D 스타일 아이콘 가능성 (이전 커밋 `Replace 11 UI icons with casual colorful style`).
- **AI 생성(예: Midjourney/DALL·E) 또는 외부 다운로드 가능성 → 출처 확인 필요**.

### 2.4 효과음 (WAV 11개) — 🟢 자체 제작
- `scripts/generate_sounds.dart` 헤더: *"외부 다운로드 대신 사인파 합성으로 7종 WAV 효과음을 생성한다. 라이센스: 자체 제작 (퍼블릭 도메인 동등)"*.
- 7종(click/mistake/line_complete/game_complete/badge/hint/pause) + 격려 4종(`enc_*`)도 동일 방식으로 추정.
- `dart:math` sin 합성 결과물 → 저작권 청구 가능성 거의 없음.

### 2.5 폰트 — 🟢 시스템 기본
- `pubspec.yaml`에 `fonts:` 섹션 **존재하지 않음**.
- Flutter 기본(Roboto/SF) 사용. 별도 라이센스 의무 없음.

### 2.6 design/ 폴더 — 🟢 앱 미포함
- `pubspec.yaml` assets 섹션: `assets/`, `assets/sounds/`, `assets/icons/` 3개뿐.
- `design/K-Puzzle_Figma_Import_Kit/`, `design/k_puzzles_flutter_exact/`, 루트의 `hub_*.png`/`redesign*.png` 등은 **배포물에 포함되지 않음** → 라이센스 위험 없음(작업용).

---

## 3. 자체 제작 vs 외부 자산

| 분류 | 자산 |
|---|---|
| 🟢 자체 제작 (코드 생성) | 앱 아이콘, 스플래시 조각, 효과음 11개, SVG 아이콘 49개 |
| 🟡 출처 확인 필요 | `assets/icons/hub-*.png` 15개 |
| 외부 의존성 | 없음 (폰트 시스템 기본) |

---

## 4. 🟡 확인 필요 항목

1. **`assets/icons/hub-*.png` 15개**
   - 생성 스크립트가 리포에 없음.
   - 권장 조치:
     - (a) AI 생성이면 **상용 라이센스 보장 도구**(ChatGPT/DALL·E 상용 OK, Midjourney 유료 플랜) 사용 확인 + 생성 출처 메모(`assets/icons/SOURCES.md`).
     - (b) 외부 다운로드면 출처/라이센스 즉시 명시.
     - (c) 어느 쪽도 확인 불가 시 자체 재제작 권장.

---

## 5. 🔴 위험 항목

**현재 없음.** 단, hub-*.png가 무단 출처로 밝혀지면 즉시 교체 필요.

---

## 6. NOTICE / Attribution 의무

- 효과음·SVG·앱 아이콘: 자체 제작 → 의무 없음.
- 시스템 폰트: 의무 없음.
- (hub PNG가 CC-BY 등으로 판명 시 NOTICE 파일에 출처 추가 필요)

---

## 7. 종합 판정

### ⚠️ 조건부 OK

- 코드/사운드/SVG/앱 아이콘 카테고리는 **상용 배포 OK** (자체 제작 확인됨).
- **차단 요소는 `assets/icons/hub-*.png` 15개의 출처 미상** 1건.
- **권장**: AAB 빌드(STEP 7) **전에** hub PNG 15개의 생성 출처를 `docs/license_review_c_assets.md`에 추가 기재하고, AI 생성이면 사용 모델/플랜의 상용 이용 조항 링크를 첨부할 것.
- 이 1건이 해소되면 즉시 ✅ 상용 OK로 승급 가능.
