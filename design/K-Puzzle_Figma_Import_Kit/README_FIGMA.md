# K-퍼즐 Figma Import Kit

이 패키지는 Figma에서 편집 가능한 벡터 원본으로 사용할 수 있도록 만든 SVG 기반 디자인 원본입니다.

## 가져오기
1. Figma 파일을 엽니다.
2. `K-Puzzle_Card_Master.svg`를 Figma 캔버스로 드래그합니다.
3. 필요하면 `Ungroup`하여 카드, 배지, 장식 요소를 각각 분리합니다.
4. 색상은 Fill/Stroke에서 변경합니다.
5. 숫자와 제목은 Figma 텍스트 레이어로 다시 입력하면 가장 안정적으로 편집할 수 있습니다.

## 포함 파일
- `K-Puzzle_Card_Master.svg`: 전체 디자인 보드
- `components/card_*.svg`: 8개 카드 개별 원본
- `components/badge_*.svg`: 8개 숫자 배지
- `components/sparkles.svg`: 스파클 장식
- `components/corner_highlights.svg`: 우하단 하이라이트
- `tokens/design_tokens.json`: 컬러/크기 토큰

## 참고
이 환경에서는 Figma 네이티브 `.fig` 바이너리 파일을 직접 생성할 수 없어,
Figma에서 가장 안정적으로 불러와 편집할 수 있는 SVG 원본 패키지로 제공합니다.
