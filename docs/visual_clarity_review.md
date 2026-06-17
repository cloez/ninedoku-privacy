# 시각 명료성 UX 검토 보고서

> 검토 대상: Ninedoku 13게임 영역/그룹/케이지 시각화
> 검토일: 2026-06-05
> 검토자: 모바일 UX 전문가
> 트리거: 사용자 피드백 — "킬러스도쿠 점선이 잘 눈에 들어오지 않음. 점선으로 묶인 케이지를 색상으로 표현하거나 점선에 색상을 입혀 묶음 표시를 명확히 해야 함."

---

## 0. 요약 (Executive Summary)

| 게임 | 그룹화 방식 | 현 상태 평가 | 우선순위 |
|---|---|---|---|
| killer_sudoku | 점선만 (white38/black38, 1.5px) | 🔴 심각 — 명도 대비 낮음, 시각 충돌 | **P0** |
| jigsaw_sudoku | 영역 배경색(9색) + 굵은 경계선 2.5px | 🟢 양호 — 모범 사례 | — |
| star_battle | 영역 배경색(10색) + 굵은 경계선 2.5px | 🟢 양호 — 모범 사례 | — |
| kakuro | 검정 셀 vs 흰 셀 (3A3A3A vs white) | 🟢 양호 | — |
| nonograms | 5칸 단위 굵은선 1.5px + 얇은선 0.5px | 🟡 보통 — 굵은선 대비 약함 | P2 |
| tents | 격자 + 텍스트 색상 구분 | 🟢 양호 | — |
| light_up | 벽 진한 회색 + 셀 흰색 | 🟢 양호 | — |
| minesweeper | 닫힘(C0C0C0) vs 열림(E8E8E8) | 🟡 보통 — 명도 차 약함 | P3 |
| sudoku / binairo / yin_yang / futoshiki / skyscrapers | 영역 그룹화 개념 없음 (격자선만) | 해당없음 | — |

**핵심 결론**: killer_sudoku는 동일한 "불규칙 영역" 게임인 jigsaw/star_battle이 이미 모범 패턴(배경색+굵은 경계)을 확립했음에도, 점선 단일 표현에 머물러 일관성과 인지성 모두 떨어진다. **옵션 C(옅은 배경색 + 채도 있는 점선)** 적용을 권장.

---

## 1. 현재 구현 분석

### 1.1 killer_sudoku — 🔴 심각

**파일**: `lib/games/killer_sudoku/widgets/killer_sudoku_board_widget.dart`

**현재 케이지 표시 사양**:
- 점선만 사용 (배경색 없음)
- 색상: `Colors.white38` (다크) / `Colors.black38` (라이트) → alpha 약 38/255 ≈ 15%
- strokeWidth: 1.5px
- dashLength 4px, gapLength 3px
- inset 2px (격자선과 겹침 방지)
- 합계 텍스트: `Colors.white60` / `Colors.black54`, 셀 크기의 22%

**선택 시 케이지 강조**: amber.withAlpha(0.10~0.12) — 선택했을 때만 케이지가 보임

**UX 4기준 평가**:

| 기준 | 평가 | 근거 |
|---|---|---|
| 1. 즉시 인지성 | ❌ | 점선 명도가 격자선(white12/black12)보다 미세하게 진할 뿐. 한눈에 케이지 경계가 안 잡힘. 셀 하나만 봐서는 어느 케이지인지 1초 안에 식별 불가 |
| 2. 색맹 대응 | ⚠️ | 색이 무채색이라 색맹 영향은 없으나, 그것이 곧 "구분이 안 됨"으로 직결 |
| 3. 시각 부담 | ✅ | 너무 약해서 부담이 없는 게 아니라 정보 전달 자체에 실패 |
| 4. 풀이 집중도 | ❌ | 사용자가 매번 케이지 경계를 추적하느라 인지 부담 증가. "이 셀이 어느 합계 그룹인가?" 확인을 위해 시선이 자주 좌상단 합계 숫자로 이동 |

**문제 진단**:
1. **명도 대비 부족**: 라이트 모드 black38(≈15% opacity) 점선은 흰 배경 대비 W3C 1.5:1 미만으로 추정 — WCAG 권장 3:1 미달
2. **격자선과의 시각 충돌**: 얇은 격자선(0.5px) + 점선(1.5px) + 박스 굵은선(2.0px)이 같은 무채색 톤에서 경쟁
3. **케이지 식별을 선택에 의존**: 셀을 탭해야만 amber 배경으로 케이지가 드러남 → 풀기 전에 케이지 구조를 한눈에 파악하기 어려움

### 1.2 jigsaw_sudoku — 🟢 양호 (모범 사례)

**파일**: `lib/games/jigsaw_sudoku/widgets/jigsaw_sudoku_board_widget.dart`

**현재 사양**:
- **배경색**: 9개 영역에 9색 팔레트 (라이트 alpha 0x30=18.8%, 다크 alpha 0x25=14.5%)
  - 빨강 E57373, 파랑 64B5F6, 초록 81C784, 주황 FFB74D, 보라 BA68C8, 청록 4DD0E1, 노랑 FFD54F, 분홍 F06292, 갈색 A1887F
- **영역 경계선**: black87/white70, 2.5px 굵게
- **얇은 격자선**: black12/white12, 0.5px

**UX 평가**:
| 기준 | 평가 |
|---|---|
| 즉시 인지성 | ✅ 색상 + 굵은 경계 이중 인코딩으로 강한 인지 |
| 색맹 대응 | ⚠️ 색상만 보면 적록 색맹은 빨강(E57373)/초록(81C784) 구분 어려움. 다만 굵은 경계선(2.5px)이 backup 채널로 작용 → 적정 |
| 시각 부담 | ✅ alpha 15~19%로 옅게 유지 — 숫자 가독성 보존 |
| 집중도 | ✅ 풀이 중 영역이 자연스레 보임 |

### 1.3 star_battle — 🟢 양호 (모범 사례)

**파일**: `lib/games/star_battle/widgets/star_battle_board_widget.dart`

**현재 사양**:
- **배경색**: 10개 파스텔 색상 (라이트 모드 E3F2FD, FCE4EC 등 — 모두 명도 90% 이상의 매우 옅은 톤)
- **다크 배경색**: 1A237E, 880E4F 등 채도 있는 어두운 톤 — 다소 무거우나 별/X 대비는 확보
- **경계선**: black87/white70, 2.5px (jigsaw와 동일)

**UX 평가**: jigsaw와 동일 패턴, 양호. 다만 다크 모드 색상이 라이트보다 채도가 높아 별(amber)과의 대비가 약해질 수 있음 → 모니터링 권장 수준.

### 1.4 기타 게임 (부가 점검)

**kakuro** 🟢 — 검정 셀(3A3A3A, 다크 2A2A2A) vs 흰 셀(FFF, 다크 1A1A1A)의 명도 차가 충분히 큼. 대각선 분할 + down/across 힌트 위치(좌하/우상)도 명확.

**nonograms** 🟡 — 5칸 단위 굵은선이 1.5px(white24/black26)에 불과해 일반 격자선(0.5px, white12/black12)과의 굵기 비가 3배지만 명도 대비가 약함. 큰 보드(20x20+)에서 5칸 단위 구분이 잘 안 보일 가능성. **개선 권장**: 굵은선을 black38, 2.0px로 강화.

**tents** 🟢 — 나무/텐트는 텍스트 색상(녹색/빨강)으로 명확히 구분. 행/열 합계 숫자도 충족 시 녹색, 초과 시 빨강으로 시각화.

**light_up** 🟢 — 벽(2D2D2D/333333)과 흰 셀의 명도 차 매우 큼. 벽 숫자(white)는 검정 배경에서 4.5:1 이상 확보.

**minesweeper** 🟡 — 닫힘(C0C0C0) vs 열림(E8E8E8)의 명도 차가 작아 그리드 인식이 약함. 클래식 디자인 전통이긴 하나, 모바일 작은 화면에서 더 큰 명도 차 권장 (예: 닫힘 BDBDBD, 열림 F5F5F5).

---

## 2. UX 가이드 — 개선 방향 권고

### 2.1 핵심 원칙

1. **이중 인코딩 (Dual-encoding)**: 영역 구분은 항상 **색상 + 경계선** 두 채널로 표현. 색맹 사용자도 한 채널만으로 구분 가능해야 한다.
2. **인지성 우선, 대비는 옅게**: 옅은 배경(alpha 12~20%)으로 숫자 가독성을 해치지 않으면서도 첫눈에 영역이 보이게 한다.
3. **점선은 색이 있을 때만 유효**: 무채색 점선은 격자선과 시각 충돌. 점선을 쓴다면 채도 있는 색상(케이지 배경색의 어두운 변형)이어야 한다.
4. **선택 의존 금지**: 풀이 시작 전, 비선택 상태에서도 영역 구조가 완전히 드러나야 한다.
5. **일관성**: 같은 컨셉(불규칙 영역)을 다루는 게임은 같은 시각 언어를 쓴다. killer_sudoku도 jigsaw/star_battle과 일관성을 갖춰야 한다.

### 2.2 killer_sudoku — 권장 옵션

**3가지 개선안 트레이드오프**:

| 옵션 | 인지성 | 색맹 대응 | 시각 부담 | 풀이 방해 | 종합 |
|---|---|---|---|---|---|
| **A**: 배경색만 (점선 제거) | ★★★★ | ★★★★ (이웃 케이지가 같은 색 안 되도록 분배 시) | ★★★ | ★★ — 합계 숫자가 색 위에서 흐려질 위험 | ★★★ |
| **B**: 점선만 색상 강화 (black54, 2.0px) | ★★★ | ★★★ (굵기 채널 보조) | ★★★★ | ★★★ — 합계 숫자에 영향 없음 | ★★★ |
| **C**: 옅은 배경색 + 채도 있는 점선 | ★★★★★ | ★★★★ | ★★★★ | ★★★★ | **★★★★★ 권장** |

#### 권장: 옵션 C (배경색 + 케이지 색상 점선)

**구현 사양**:

```
케이지 배경:
  - 라이트: alpha 0x14 (≈8%) — jigsaw(0x30)보다 더 옅게. 케이지가 많고 작아서 색이 누적되면 어지러움
  - 다크:   alpha 0x18 (≈9%)
  - HSL 기반 색상 풀 (채도 60%, 명도 라이트=85% / 다크=40%)

점선:
  - 색상: 같은 케이지 배경색 H를 채도 70%, 명도 라이트=40% / 다크=70%로 변환
  - strokeWidth: 1.8px (현 1.5 → 1.8)
  - dashLength 5, gapLength 3
  - inset 2.0 유지

합계 텍스트:
  - 굵기: FontWeight.bold (유지)
  - 색상: 라이트 black87, 다크 white87 (현 black54/white60에서 강화)
  - 배경 명도 85% 위 black87 = WCAG 4.5:1 이상 확보
  - 폰트 크기: cellSize * 0.24 (현 0.22 → 0.24)

이웃 케이지 색상 분배:
  - 그래프 4색 정리 (Four-color theorem) 적용
  - 또는 케이지 ID 해시 → 색상 풀 회전 + 인접 케이지 색 충돌 시 다음 색
```

**색상 팔레트 (HSL 기반, HEX 예시)**:

라이트 모드 케이지 배경 (alpha 적용 전 base):
```
H=  0°: #F5C6CB (빨강계)
H= 30°: #FFE0B2 (주황계)
H= 60°: #FFF59D (노랑계)
H=120°: #C8E6C9 (초록계)
H=180°: #B2EBF2 (청록계)
H=210°: #BBDEFB (파랑계)
H=270°: #D1C4E9 (보라계)
H=330°: #F8BBD0 (분홍계)
```

라이트 모드 점선 색상 (대응):
```
H=  0°: #C62828
H= 30°: #E65100
H= 60°: #F9A825
H=120°: #2E7D32
H=180°: #00838F
H=210°: #1565C0
H=270°: #6A1B9A
H=330°: #AD1457
```

**다크 모드**: 배경은 동일 H, 명도 30%, alpha 0x18. 점선은 동일 H, 명도 70%.

### 2.3 jigsaw_sudoku — 현 상태 유지

이미 모범. 다만 색맹 사용자 대비 색상 한 가지(예: 빨강 E57373)는 적록 색맹에게 초록(81C784)과 혼동될 수 있음. 굵은 경계선(2.5px)이 backup 채널로 충분히 작동하므로 **변경 불요**. 장기적으로 색맹 친화 팔레트 옵션 추가 검토.

### 2.4 star_battle — 현 상태 유지 (다크 모드만 미세 조정 권장)

다크 모드 배경색(880E4F 어두운 분홍, E65100 어두운 주황)은 채도가 높아 별(amber.shade300)과의 대비가 일부 영역에서 약해짐. **권장**: 다크 모드 배경 채도를 낮춰 alpha 30% 적용한 색상으로 통일.

### 2.5 nonograms — P2 개선

5칸 단위 굵은선 강화:
- 현: `Colors.white24 / Colors.black26`, 1.5px
- 개선: `Colors.white54 / Colors.black54`, 2.0px

### 2.6 minesweeper — P3 개선 (선택적)

닫힘/열림 명도 차 확대:
- 현: 닫힘 C0C0C0 / 열림 E8E8E8 (라이트)
- 개선: 닫힘 BDBDBD / 열림 F5F5F5

또는 닫힘 셀에 미세한 사면 효과(emboss)를 강화하여 입체감으로 구분.

---

## 3. 구현 가이드 (개발자 참고)

### 3.1 인접 케이지 색상 충돌 방지 (killer_sudoku)

**간단한 해시 회전 방식** (4색 정리 미적용 시):
```dart
// 케이지 ID로 색상 결정 + 인접 케이지와 같은 색이면 다음 색으로 회전
final palette = isDark ? _darkPalette : _lightPalette; // 8색
final cageColors = <Cage, int>{};
for (final cage in board.cages) {
  var idx = cage.id % palette.length;
  // 인접 케이지(케이지 간 공유 경계 셀이 있는) 색과 충돌 회피
  for (var tries = 0; tries < palette.length; tries++) {
    final hasConflict = _adjacentCages(cage).any((adj) =>
      cageColors[adj] == idx);
    if (!hasConflict) break;
    idx = (idx + 1) % palette.length;
  }
  cageColors[cage] = idx;
}
```

**완전한 4색 정리** (선택적): 케이지 인접 그래프를 만들고 Greedy/Welsh-Powell 알고리즘. 9×9 보드의 케이지 수(보통 25~35개) 규모에서 4색이면 충분.

### 3.2 색상 팔레트 상수 추가 위치

`lib/shared/constants/app_colors.dart`에 다음 추가 권장:
```dart
class AppColors {
  // 기존...

  // 영역/케이지 색상 팔레트
  static const cagePaletteLight = [...];
  static const cagePaletteDark = [...];
  static const cageBorderPaletteLight = [...];
  static const cageBorderPaletteDark = [...];
}
```

### 3.3 점선 그리기 — 현 코드 활용

`_drawDashedLine`은 그대로 사용. paint.color만 케이지별로 다르게 주입하면 됨.

### 3.4 합계 텍스트 가독성

배경색 위에 텍스트를 올릴 때 가독성 보장 패턴:
```dart
// 1) 배경에 미세한 흰 박스 (라이트) / 검정 박스 (다크) 깔기
final bgPaint = Paint()
  ..color = isDark
    ? Colors.black.withValues(alpha: 0.35)
    : Colors.white.withValues(alpha: 0.6);
canvas.drawRRect(
  RRect.fromRectAndRadius(textBgRect, Radius.circular(2)),
  bgPaint,
);
// 2) 그 위에 합계 텍스트
```
또는 텍스트 자체에 thin outline 추가.

---

## 4. 트레이드오프 — 모바일 기획자 결정 필요 사항

PM/GD 합의가 필요한 항목:

| 항목 | 옵션 A | 옵션 B | UX 권장 |
|---|---|---|---|
| killer 케이지 표현 | 옵션 C 풀 적용 | 옵션 B만(점선 강화) | **옵션 C** — 사용자 피드백 직접 해결 |
| 색상 가짓수 | 4색(4색정리) | 8색(다양성) | 8색 + 인접 충돌 회피 — 시각적 풍부함 |
| 색맹 모드 토글 | 설정에 추가 | 도입 안 함 | 설정 추가 — 장기 접근성 향상 |
| jigsaw/star_battle 통합 변경 | 일괄 색맹 친화 팔레트 적용 | 현 상태 유지 | 현 상태 유지 — 변경 비용 대비 가치 낮음 |
| nonograms 굵은선 강화 | 이번 사이클 포함 | 다음 사이클 | 다음 사이클 — killer 우선 |

---

## 5. 향후 방향

### 5.1 단기 (이번 사이클)
- **killer_sudoku 옵션 C 적용** — 사용자 피드백 직접 해결
- 합계 텍스트 명도 대비 4.5:1 검증 (라이트/다크 양쪽)
- QA: 케이지 인접 색상 충돌 케이스 100문제 샘플링 검증

### 5.2 중기 (다음 1~2 사이클)
- 설정 화면에 "고대비 모드" 토글 추가 (전 게임 공통)
- 색맹 친화 팔레트 옵션 (jigsaw, star_battle, killer 공용)
- nonograms 5칸 굵은선 강화

### 5.3 장기
- `docs/visual_design_guidelines.md`로 게임별 시각 일관성 가이드라인 통합 문서화
- 새 게임 추가 시 영역/그룹 시각화 패턴 체크리스트 적용 (P0 항목)

---

## 부록 A. 영향 받는 파일 (구현 시)

```
lib/games/killer_sudoku/widgets/killer_sudoku_board_widget.dart  (주 수정)
lib/shared/constants/app_colors.dart                              (팔레트 추가)
test/games/killer_sudoku/                                         (시각 회귀 테스트)
```

## 부록 B. 평가 기준 출처

- WCAG 2.1 SC 1.4.3 (Contrast Minimum): 텍스트 4.5:1
- WCAG 2.1 SC 1.4.11 (Non-text Contrast): UI 컴포넌트 3:1
- WCAG 2.1 SC 1.4.1 (Use of Color): 색상만으로 정보를 전달하지 않음 → 이중 인코딩 원칙의 근거
