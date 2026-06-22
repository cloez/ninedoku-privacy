# K-퍼즐 Flutter UI

승인된 이미지 스타일을 Flutter 컴포넌트로 재구성한 프로젝트입니다.

## 포함 화면

- 게임 허브
- 13개 게임별 메인화면
  - 스도쿠
  - 비나이로
  - 지뢰찾기
  - 음양
  - 노노그램
  - 킬러 스도쿠
  - 스타 배틀
  - 라이트업
  - 후토시키
  - 텐트
  - 직소 스도쿠
  - 빌딩
  - 카쿠로
- 스도쿠 실제 플레이 화면(세로/가로 반응형)
- 설정 화면

## 구조

```text
lib/
 ├─ app/
 ├─ data/
 ├─ models/
 ├─ screens/
 │   ├─ all_game_home_screens.dart
 │   ├─ game_home_screen.dart
 │   ├─ game_hub_screen.dart
 │   ├─ settings_screen.dart
 │   └─ play/sudoku_play_screen.dart
 ├─ theme/
 └─ widgets/
```

## 실행

```bash
flutter pub get
flutter run
```

## 디자인 일치 방식

- 승인 이미지의 블루·바이올렛 그라데이션, 둥근 대형 카드, 소프트 그림자, 반짝임 장식, 흰색 입체 아이콘 프레임을 공통 위젯으로 구현했습니다.
- 13개 게임 화면은 동일한 `GameHomeScreen` 구조를 사용하면서 각 게임의 색상, 아이콘, 슬로건, 설명, 규칙을 데이터로 주입합니다.
- 화면이 길어지는 경우 `CustomScrollView`로 자연스럽게 스크롤되며 좌우 여백은 유지됩니다.
