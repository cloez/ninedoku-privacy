# Sudoku 튜토리얼 상세 컨텐츠

> **이 문서는 스도쿠 전용 컨텐츠이자, 다른 12개 게임 튜토리얼 작성 시 그대로 복제해 채우는 템플릿입니다.**
> 공통 화면 설계는 `docs/tutorial_screen_spec.md` 참조.

---

## 0. 메타 정보

| 항목 | 값 |
|---|---|
| 게임 ID | `sudoku` |
| 단계 수 | 5 |
| 평균 학습 시간 (가정) | 50초 (Skip 제외) |
| 필수 단계 | S1, S2, S3, S5 |
| 옵션 단계 | S4 (메모/힌트) |
| 연습 단계 | S5 — 1칸 채우기 |

---

## 1. 단계 정의

### STEP 1 — 스도쿠란?

| 키 | 값 |
|---|---|
| `tutorial.sudoku.step1.title` | "스도쿠란?" |
| `tutorial.sudoku.step1.description` | "9×9 칸을 1부터 9까지의 숫자로 채우는 논리 퍼즐이에요. 정답은 항상 하나뿐입니다." |
| 일러스트 | 3×3 미니 보드 — 정답 채워진 상태(`MiniBoardIllustration`) |
| 사용자 행동 | 읽기 + Next 탭 |
| TalkBack 라벨 | "스도쿠 소개. 9×9 보드를 1에서 9 숫자로 채워요." |

미니 보드 데이터:
```
5 3 7
6 1 9
2 8 4
```

### STEP 2 — 기본 규칙 (행/열)

| 키 | 값 |
|---|---|
| `tutorial.sudoku.step2.title` | "행과 열" |
| `tutorial.sudoku.step2.description` | "가로 한 줄과 세로 한 줄에는 1부터 9까지 숫자가 정확히 한 번씩 들어가야 해요." |
| 일러스트 | 9×9 축약형 — 한 행 + 한 열을 색으로 강조, 중복된 셀에 ⚠ 표시 |
| Overlay | `errorMark`(중복 셀) + `okMark`(올바른 행) |
| 사용자 행동 | Next |

### STEP 3 — 3×3 박스 규칙

| 키 | 값 |
|---|---|
| `tutorial.sudoku.step3.title` | "3×3 박스" |
| `tutorial.sudoku.step3.description` | "9×9는 굵은 선으로 9개의 3×3 박스로 나뉘어요. 각 박스 안에도 1–9가 한 번씩 들어갑니다." |
| 일러스트 | 9×9 — 좌상단 박스 노란색 강조, 박스 내 숫자 빛남 |
| 사용자 행동 | Next |

### STEP 4 — 조작과 메모 (선택 표시 + 메모 모드)

| 키 | 값 |
|---|---|
| `tutorial.sudoku.step4.title` | "조작 방법" |
| `tutorial.sudoku.step4.description` | "빈 칸을 탭하고 아래 숫자 패드에서 숫자를 골라요. 메모 모드로 후보 숫자를 적어둘 수도 있어요." |
| 일러스트 | 손가락 아이콘 → 셀 → 키패드 강조 애니메이션 |
| 사용자 행동 | Next |
| 비고 | motionScale=0이면 화살표 정적 표시 |

### STEP 5 — 직접 풀어보기 (연습)

| 키 | 값 |
|---|---|
| `tutorial.sudoku.step5.title` | "직접 풀어보기" |
| `tutorial.sudoku.step5.description` | "노란 칸에 들어갈 숫자는 무엇일까요?" |
| 일러스트 | 인터랙티브 4×4 또는 작은 3×3 보드 (스도쿠 보드 위젯 readonly+forcedTarget) |
| `tutorial.sudoku.step5.hint` | "같은 줄에 어떤 숫자들이 있는지 살펴봐요." |
| 정답 셀 | (1, 1) |
| 정답 값 | 4 |
| 사용자 행동 | 셀 탭 → 숫자 입력 → 정답 확인 |

연습 보드 (4×4, 1–4 미니 스도쿠로 단순화):
```
1 . 3 2
3 2 4 1
2 4 1 3
4 3 2 .
```
(목표 셀: 행1, 열2 — 정답 4)

> **GD 의견**: 9×9 풀 보드는 신규 사용자에게 부담. 학습 목적상 4×4 미니 스도쿠 사용.
> **GC 의견**: 4×4지만 행/열/2×2 박스 규칙이 동일하게 적용되므로 학습 전이 OK.

---

## 2. 완료 화면

| 키 | 값 |
|---|---|
| `tutorial.sudoku.complete.title` | "준비 완료!" |
| `tutorial.sudoku.complete.body` | "기본 규칙을 익혔어요. 첫 퍼즐을 시작해볼까요?" |
| `tutorial.sudoku.complete.cta` | "지금 플레이" |
| 체크박스 | "다시 보지 않기" |

---

## 3. 4언어 문구 표 (1~5단계)

| 키 | 한국어 | English | 日本語 | 中文 |
|---|---|---|---|---|
| step1.title | 스도쿠란? | What is Sudoku? | 数独とは? | 什么是数独? |
| step1.description | 9×9 칸을 1부터 9까지의 숫자로 채우는 논리 퍼즐이에요. | A logic puzzle: fill a 9×9 grid with digits 1 to 9. | 9×9のマスを1から9の数字で埋める論理パズルです。 | 用 1 到 9 的数字填满 9×9 网格的逻辑谜题。 |
| step2.title | 행과 열 | Rows & Columns | 行と列 | 行与列 |
| step2.description | 가로·세로 한 줄에 1–9가 한 번씩 들어가요. | Each row and column contains 1–9 exactly once. | 各行・各列に1–9が一度ずつ入ります。 | 每行每列各含 1–9 各一次。 |
| step3.title | 3×3 박스 | 3×3 Boxes | 3×3 ボックス | 3×3 宫 |
| step3.description | 굵은 선으로 나뉜 9개 박스 안에도 1–9가 한 번씩 들어가요. | Each of the nine 3×3 boxes also contains 1–9 once. | 太線で区切られた9つのボックスにも1–9が一度ずつ。 | 九个 3×3 宫格内也各含 1–9 各一次。 |
| step4.title | 조작 방법 | How to Play | 操作方法 | 操作方式 |
| step4.description | 빈 칸을 탭하고 숫자 패드에서 입력하세요. 메모 모드로 후보도 적을 수 있어요. | Tap an empty cell, then pick a digit. Use notes for candidates. | 空マスをタップして数字パッドから入力。メモも使えます。 | 点空格选数字。可用笔记记录候选。 |
| step5.title | 직접 풀어보기 | Try it | やってみよう | 试一试 |
| step5.description | 노란 칸에 들어갈 숫자는? | What digit fits in the yellow cell? | 黄色のマスに入る数字は? | 黄色格中应填什么? |
| step5.hint | 같은 줄에 어떤 숫자가 있는지 보세요. | Check the row and column. | 同じ列にある数字を見ましょう。 | 看看同行同列已有的数字。 |
| complete.title | 준비 완료! | All set! | 準備完了! | 准备就绪! |
| complete.cta | 지금 플레이 | Play now | 今すぐプレイ | 立即开始 |

---

## 4. 데이터 모델 인스턴스 예시 (Dart)

```dart
final sudokuTutorial = GameTutorial(
  gameId: 'sudoku',
  steps: [
    // S1
    TutorialStep(
      titleKey: 'tutorial.sudoku.step1.title',
      descriptionKey: 'tutorial.sudoku.step1.description',
      illustration: MiniBoardIllustration(
        gameId: 'sudoku',
        board: [
          [5, 3, 7],
          [6, 1, 9],
          [2, 8, 4],
        ],
        overlay: OverlayKind.okMark,
      ),
    ),
    // S2
    TutorialStep(
      titleKey: 'tutorial.sudoku.step2.title',
      descriptionKey: 'tutorial.sudoku.step2.description',
      illustration: MiniBoardIllustration(
        gameId: 'sudoku',
        board: _exampleRowColBoard,
        highlights: [
          CellHighlight(0, 0, HighlightStyle.info),  // 행 강조
          // ... 한 행 + 한 열
        ],
        overlay: OverlayKind.errorMark, // 중복 셀에 ⚠
      ),
    ),
    // S3
    TutorialStep(
      titleKey: 'tutorial.sudoku.step3.title',
      descriptionKey: 'tutorial.sudoku.step3.description',
      illustration: MiniBoardIllustration(
        gameId: 'sudoku',
        board: _exampleBoxBoard,
        highlights: _highlightTopLeftBox(),
      ),
    ),
    // S4
    TutorialStep(
      titleKey: 'tutorial.sudoku.step4.title',
      descriptionKey: 'tutorial.sudoku.step4.description',
      illustration: IconIllustration(Icons.touch_app_rounded),
    ),
    // S5 — 인터랙티브 연습
    TutorialStep(
      titleKey: 'tutorial.sudoku.step5.title',
      descriptionKey: 'tutorial.sudoku.step5.description',
      illustration: MiniBoardIllustration(
        gameId: 'sudoku',
        board: _practiceBoard,
        highlights: [CellHighlight(0, 1, HighlightStyle.arrow)],
      ),
      practice: InteractivePractice(
        gameId: 'sudoku',
        initialBoard: _practiceBoard,
        target: CellTarget(0, 1),
        correctValue: 4,
        hintKey: 'tutorial.sudoku.step5.hint',
      ),
    ),
  ],
);
```

---

## 5. 다른 12게임 작성 시 사용할 템플릿

각 게임 컨텐츠 문서를 새로 만들 때 다음 섹션을 그대로 복제하고 채우세요:

```markdown
# {GameName} 튜토리얼 상세 컨텐츠

## 0. 메타 정보
| 게임 ID | `{gameId}` |
| 단계 수 | {N} |
| 필수 단계 | S1, S2, ... |
| 연습 단계 | S{X} — {요약} |

## 1. 단계 정의
### STEP 1 — {제목}
- 키: `tutorial.{gameId}.step1.title`, `.description`
- 일러스트: ...
- 사용자 행동: ...

(STEP 2 ~ N 반복)

## 2. 완료 화면
## 3. 4언어 문구 표
## 4. 데이터 모델 인스턴스
```

### 12게임 작성 체크리스트

| 게임 | 핵심 차별 포인트 | 주의 |
|---|---|---|
| Binairo | "셋 연속 금지" 강조 — 색 외 패턴 필요 | 0/1 표시법 통일 |
| Minesweeper | 깃발 vs 열기 두 입력 모드 | 연습 보드 안전성 보장 |
| Yin-Yang | "연결성" 시각화가 어려움 — 화살표 + 점선 | 2×2 단색 금지 시각 예 |
| Nonograms | 단서 줄 의미 학습이 핵심 | 작은 5×5 예시 권장 |
| Killer Sudoku | 케이지(점선)와 합 인식 | 스도쿠 학습 선행 가정 |
| Star Battle | 영역 경계 강조, 별 인접 금지 | "N개"의 N 표기 명확히 |
| Light Up | 빛 전파 시각화 | 검은 셀 숫자 의미 |
| Futoshiki | 부등호 깜빡임 | < > 방향성 학습 |
| Tents | 나무-텐트 페어링 | 단서 숫자(가장자리) |
| Jigsaw Sudoku | 직소 박스 모양 강조 | 스도쿠 학습 선행 가정 |
| Skyscrapers | 가시성 시각화 (3D 일러스트) | 단서 의미 단계 분리 |
| Kakuro | 단서 셀(분할) 의미 | 가능 조합 표 노출 |

---

## 6. 합의 노트 (Sudoku 한정)

- **GD**: S5 연습은 4×4 미니 스도쿠로 단순화 — OK
- **UX**: S4 키패드 묘사는 정적 화살표로 충분 (모션 감소 모드 친화) — OK
- **GC**: 9×9 풀 보드 정답 채우기는 학습 곡선 가파름 → 4×4 동의
- **QA**: 연습 보드 정답 1개로 강제, 오답 3회 후 "정답 보기" — OK
- **결정**: 5단계 확정, 자동 표시 ON, ? 아이콘 항상 노출

---

## 7. QA 시나리오 (STEP 5)

1. 첫 실행 → 스도쿠 첫 진입 시 자동 표시 ✅
2. Skip → 다시 첫 진입해도 자동 표시 안 됨, ? 아이콘은 보임
3. S5에서 정답(4) 입력 → 펄스 + "완료" 활성
4. S5에서 오답(1, 2, 3) 입력 → 흔들림 + 힌트 노출
5. 오답 3회 → "정답 보기" 버튼 등장
6. "다시 보지 않기" 체크 후 완료 → 다음 진입 시 자동 표시 안 됨
7. 설정 → 튜토리얼 초기화 → 다시 자동 표시
8. TalkBack 활성화 → S1~S5 순차 안내, 셀 라벨 정확
9. 텍스트 1.6배 → 레이아웃 깨지지 않음
10. 4언어 전환 → 모든 키 번역 존재
