# 킬러스도쿠 케이지 시각화 개선 — 구현 사양서

> 작성: 모바일 기획자
> 일자: 2026-06-05
> 입력: docs/visual_clarity_review.md (UX 가이드)
> PM 결정: 옵션 C (배경 + 점선) + 8색 + 인접 회피

---

## 1. 기능 요구사항

### 1.1 케이지 배경 색상
- 각 케이지에 옅은 배경색 채움 (alpha 8~10%)
- 8색 팔레트에서 인접 케이지와 다른 색 자동 선택
- 라이트/다크 모드 모두 동작

### 1.2 케이지 경계선 (점선)
- 점선 색상: 해당 케이지의 메인 색상 (alpha 50%)
- 굵기: 1.8px (기존 1.5px → 1.8px)
- 인접 셀이 같은 케이지가 아닌 4방향에 점선

### 1.3 합계 숫자
- 위치: 케이지 좌상단 셀 안쪽 (기존 유지)
- 색상: 케이지 색상의 진한 톤 + 그림자 (가독성)
- 배경과 명도 대비 4.5:1 이상

---

## 2. 색상 팔레트 (8색)

### 2.1 라이트 모드 (배경 alpha 0x18 = 9.4%)
| # | 이름 | 메인색 HEX | 배경 알파 |
|---|------|-----------|----------|
| 0 | Blue   | `#1E88E5` | `0x181E88E5` |
| 1 | Green  | `#43A047` | `0x1843A047` |
| 2 | Orange | `#FB8C00` | `0x18FB8C00` |
| 3 | Purple | `#8E24AA` | `0x188E24AA` |
| 4 | Teal   | `#00897B` | `0x1800897B` |
| 5 | Pink   | `#E91E63` | `0x18E91E63` |
| 6 | Amber  | `#FFB300` | `0x18FFB300` |
| 7 | Indigo | `#3949AB` | `0x183949AB` |

### 2.2 다크 모드 (배경 alpha 0x22 = 13.3%)
같은 HEX 코드, 알파만 약간 증가하여 다크 배경 위에서도 식별 가능.

### 2.3 점선 색상
메인색 그대로, alpha 0x80 (50%) 적용.

---

## 3. 알고리즘 — 인접 케이지 색상 충돌 회피

### 3.1 그리디 색칠 (단순)
```dart
List<int> assignCageColors(List<Cage> cages) {
  final colors = List<int>.filled(cages.length, -1);
  
  for (int i = 0; i < cages.length; i++) {
    // i번 케이지와 인접한 케이지들의 이미 할당된 색을 수집
    final usedColors = <int>{};
    for (int j = 0; j < cages.length; j++) {
      if (i == j || colors[j] == -1) continue;
      if (_areAdjacent(cages[i], cages[j])) {
        usedColors.add(colors[j]);
      }
    }
    
    // 8색 중 사용되지 않은 첫 번째 색 선택
    for (int c = 0; c < 8; c++) {
      if (!usedColors.contains(c)) {
        colors[i] = c;
        break;
      }
    }
    // 모두 충돌하면 (드뭄) 0번 선택
    if (colors[i] == -1) colors[i] = 0;
  }
  
  return colors;
}

bool _areAdjacent(Cage a, Cage b) {
  for (final (ar, ac) in a.cells) {
    for (final (br, bc) in b.cells) {
      if ((ar - br).abs() + (ac - bc).abs() == 1) return true;
    }
  }
  return false;
}
```

### 3.2 성능
- 9×9 보드에서 케이지 수 평균 15~25개
- O(n² × m²) 복잡도 (n=케이지 수, m=평균 케이지 크기 4셀)
- 9×9에서 < 1ms 예상, 무시 가능

---

## 4. 구현 위치

### 4.1 새 파일
- `lib/games/killer_sudoku/widgets/cage_palette.dart` — 8색 팔레트 + 인접 색칠 알고리즘

### 4.2 수정 파일
- `lib/games/killer_sudoku/widgets/killer_sudoku_board_widget.dart`
  - Painter에 cageColors 필드 추가 (build 시 계산)
  - `_drawCages` 메서드 수정:
    - 배경 채움 추가
    - 점선 색상을 케이지 색상으로 변경
  - `_drawCageSums` 메서드 수정:
    - 합계 텍스트 색상을 케이지 메인색으로

---

## 5. UI 영향 점검

### 5.1 선택 셀 강조 (amber)
- 케이지 색상이 amber와 겹치면 충돌 가능
- 해결: 선택 시 케이지 배경 위에 추가로 amber border 강조 (이미 구현됨)

### 5.2 힌트 셀 강조 (yellow)
- 동일 처리 (border 추가)

### 5.3 메모 숫자
- 케이지 배경 위에 표시. 가독성 검증 필요 (alpha 9%면 거의 투명이라 영향 미미)

---

## 6. 테스트 계획

### 6.1 단위 테스트
- `cage_palette.dart`:
  - 인접 케이지는 항상 다른 색 (8색 내에서)
  - 모든 케이지에 색 할당됨 (-1 없음)

### 6.2 위젯 테스트
- 보드 위젯이 cageColors 배열 길이만큼 색을 사용하는지
- 점선/배경/합계 색상 일치

### 6.3 시각 검증
- 다양한 케이지 분할 시드로 스크린샷 비교

---

## PM 검증
✅ UX 가이드와 일치
✅ 단일 게임 범위 (사용자 영향 작음)
✅ 다국어 영향 없음 (시각만)
✅ 저장된 게임 영향 없음 (UI 레이어만 변경)
✅ 성능 영향 미미

→ **DEV 구현 진행 승인**
