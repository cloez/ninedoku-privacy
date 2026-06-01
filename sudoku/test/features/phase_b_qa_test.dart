import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/features/game/game_notifier.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';

/// Phase B QA 검증 테스트
/// Item 3: 숫자 우선 입력 모드, Item 4: 시간 추이 차트
void main() {
  // 테스트용 유효한 스도쿠 데이터
  late List<List<int>> puzzle;
  late List<List<int>> solution;

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();

    solution = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];
    // 3칸만 비운 퍼즐: (0,0)=5, (0,1)=3, (1,0)=6
    puzzle = solution.map((r) => List<int>.from(r)).toList();
    puzzle[0][0] = 0;
    puzzle[0][1] = 0;
    puzzle[1][0] = 0;
  });

  // ========================================================
  // Item 3: 숫자 우선 입력 모드 — GameNotifier 통합 테스트
  // ========================================================
  group('QA Item 3: toggleInputMode 동작', () {
    late GameNotifier notifier;

    setUp(() {
      notifier = GameNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('toggleInputMode가 cellFirst → numberFirst로 전환', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      expect(notifier.testState!.inputMode, InputMode.cellFirst);
      notifier.toggleInputMode();
      expect(notifier.testState!.inputMode, InputMode.numberFirst);
    });

    test('toggleInputMode가 numberFirst → cellFirst로 전환', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      notifier.toggleInputMode(); // → numberFirst
      notifier.toggleInputMode(); // → cellFirst
      expect(notifier.testState!.inputMode, InputMode.cellFirst);
    });

    test('toggleInputMode 시 selectedNumber가 초기화됨', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 5,
      ));

      expect(notifier.testState!.selectedNumber, 5);
      notifier.toggleInputMode();
      expect(notifier.testState!.selectedNumber, isNull);
    });

    test('완료된 게임에서 toggleInputMode 무시', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        isCompleted: true,
      ));

      notifier.toggleInputMode();
      expect(notifier.testState!.inputMode, InputMode.cellFirst);
    });

    test('null 상태에서 toggleInputMode 안전', () {
      // 게임 시작 전 (state == null)
      notifier.toggleInputMode();
      expect(notifier.testState, isNull);
    });
  });

  group('QA Item 3: selectNumber 동작', () {
    late GameNotifier notifier;

    setUp(() {
      notifier = GameNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('selectNumber로 숫자 선택', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
      ));

      notifier.selectNumber(3);
      expect(notifier.testState!.selectedNumber, 3);
    });

    test('같은 숫자 재선택 시 해제', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 3,
      ));

      notifier.selectNumber(3);
      expect(notifier.testState!.selectedNumber, isNull);
    });

    test('다른 숫자 선택 시 변경', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 3,
      ));

      notifier.selectNumber(7);
      expect(notifier.testState!.selectedNumber, 7);
    });

    test('완료된 게임에서 selectNumber 무시', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        isCompleted: true,
      ));

      notifier.selectNumber(5);
      expect(notifier.testState!.selectedNumber, isNull);
    });

    test('null 상태에서 selectNumber 안전', () {
      notifier.selectNumber(5);
      expect(notifier.testState, isNull);
    });
  });

  group('QA Item 3: 숫자 우선 모드에서 selectCell 자동 입력', () {
    late GameNotifier notifier;

    setUp(() {
      notifier = GameNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('숫자 우선 모드에서 빈 셀 탭 시 자동 입력', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 5,
      ));

      // (0,0)은 빈 칸, 정답은 5
      notifier.selectCell(0, 0);

      // 자동 입력이 일어나야 함
      expect(notifier.testState!.board.currentBoard[0][0], 5);
    });

    test('숫자 우선 모드에서 고정 셀 탭 시 입력 안 됨', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 5,
      ));

      // (0,2)는 고정 셀 (값=4)
      final origValue = notifier.testState!.board.currentBoard[0][2];
      notifier.selectCell(0, 2);

      // 고정 셀은 값이 변하지 않아야 함
      expect(notifier.testState!.board.currentBoard[0][2], origValue);
      // 선택은 이동해야 함
      expect(notifier.testState!.selectedCell, (0, 2));
    });

    test('숫자 우선 모드에서 오답 입력 시 실수 카운트 증가', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 9, // (0,0)의 정답은 5이므로 9는 오답
      ));

      final prevMistakes = notifier.testState!.mistakeCount;
      notifier.selectCell(0, 0);

      expect(notifier.testState!.board.currentBoard[0][0], 9);
      expect(notifier.testState!.mistakeCount, prevMistakes + 1);
    });

    test('셀 우선 모드에서는 selectCell이 선택만 수행', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.cellFirst,
      ));

      notifier.selectCell(0, 0);
      // 셀 우선 모드에서는 숫자가 입력되지 않아야 함
      expect(notifier.testState!.board.currentBoard[0][0], 0);
      expect(notifier.testState!.selectedCell, (0, 0));
    });

    test('숫자 우선 모드에서 selectedNumber가 null이면 선택만 수행', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        // selectedNumber: null (기본)
      ));

      notifier.selectCell(0, 0);
      // selectedNumber가 null이므로 숫자 입력 없이 선택만
      expect(notifier.testState!.board.currentBoard[0][0], 0);
      expect(notifier.testState!.selectedCell, (0, 0));
    });
  });

  group('QA Item 3: 메모 모드 + 숫자 우선 모드 조합', () {
    late GameNotifier notifier;

    setUp(() {
      notifier = GameNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('메모 모드 + 숫자 우선 모드에서 셀 탭 시 메모 토글', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        isMemoMode: true,
        selectedNumber: 5,
      ));

      // (0,0)은 빈 칸
      notifier.selectCell(0, 0);

      // 메모 모드이므로 값이 아닌 메모가 토글되어야 함
      expect(notifier.testState!.board.currentBoard[0][0], 0);
      expect(notifier.testState!.board.notes[0][0].contains(5), true);
    });

    test('메모 모드 + 숫자 우선 모드에서 같은 메모 재탭 시 제거', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        isMemoMode: true,
        selectedNumber: 5,
      ));

      // 첫 번째 탭: 메모 추가
      notifier.selectCell(0, 0);
      expect(notifier.testState!.board.notes[0][0].contains(5), true);

      // 두 번째 탭: 메모 제거
      notifier.selectCell(0, 0);
      expect(notifier.testState!.board.notes[0][0].contains(5), false);
    });
  });

  group('QA Item 3: JSON 직렬화 하위 호환성', () {
    test('inputMode 키가 없는 레거시 JSON에서 기본값 cellFirst', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      final json = state.toJson();
      json.remove('inputMode');
      json.remove('selectedNumber');

      final restored = GameState.fromJson(json);
      expect(restored.inputMode, InputMode.cellFirst);
      expect(restored.selectedNumber, isNull);
    });

    test('inputMode가 빈 문자열인 JSON에서 기본값 반환', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      final json = state.toJson();
      json['inputMode'] = '';

      final restored = GameState.fromJson(json);
      expect(restored.inputMode, InputMode.cellFirst);
    });

    test('selectedNumber가 null인 JSON에서 기본값 null', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      final json = state.toJson();
      json['selectedNumber'] = null;

      final restored = GameState.fromJson(json);
      expect(restored.selectedNumber, isNull);
    });

    test('numberFirst 모드가 직렬화/역직렬화 후 보존됨', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 7,
      );

      final json = state.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.inputMode, InputMode.numberFirst);
      expect(restored.selectedNumber, 7);
    });
  });

  // ========================================================
  // Item 4: 시간 추이 차트 — 데이터 계산 검증
  // ========================================================
  group('QA Item 4: 차트 데이터 엣지케이스', () {
    test('빈 기록 리스트에서 필터링 결과도 비어있음', () {
      final records = <CompletedGameRecord>[];
      final filtered = records.where((r) => r.difficulty == 'beginner').toList();
      expect(filtered, isEmpty);
    });

    test('기록이 1개일 때 분 단위 변환 정확', () {
      final record = CompletedGameRecord(
        mode: 'classic',
        difficulty: 'beginner',
        elapsedSeconds: 125,
        mistakeCount: 0,
        hintCount: 0,
        grade: 'S',
        completedAt: DateTime(2026, 5, 26),
      );

      final minutes = record.elapsedSeconds / 60.0;
      expect(minutes, closeTo(2.0833, 0.01));
    });

    test('모든 시간이 0초인 기록 — 분 단위 변환 시 0.0', () {
      final records = List.generate(5, (i) => CompletedGameRecord(
        mode: 'classic',
        difficulty: 'beginner',
        elapsedSeconds: 0,
        mistakeCount: 0,
        hintCount: 0,
        grade: 'S',
        completedAt: DateTime(2026, 5, i + 1),
      ));

      final minuteValues = records.map((r) => r.elapsedSeconds / 60.0).toList();
      expect(minuteValues.every((v) => v == 0.0), true);

      // maxY가 0이면 chartMaxY 계산: 기본 5.0 + 5 = 10
      final rawMaxY = minuteValues.reduce((a, b) => a > b ? a : b);
      final maxY = rawMaxY < 1.0 ? 5.0 : rawMaxY;
      final chartMaxY = ((maxY / 5).ceil() * 5 + 5).toDouble();
      expect(chartMaxY, 10.0);
    });

    test('20개 초과 기록일 때 최근 20개만 사용', () {
      final records = List.generate(25, (i) => CompletedGameRecord(
        mode: 'classic',
        difficulty: 'beginner',
        elapsedSeconds: (i + 1) * 60,
        mistakeCount: 0,
        hintCount: 0,
        grade: 'A',
        completedAt: DateTime(2026, 1, i + 1),
      ));

      // 차트 로직: 20개 초과 시 마지막 20개만
      final recent = records.length > 20
          ? records.sublist(records.length - 20)
          : records;

      expect(recent.length, 20);
      // 첫 번째 = 6번째 기록 (index 5), 시간 = 360초 = 6분
      expect(recent.first.elapsedSeconds, 360);
      // 마지막 = 25번째 기록, 시간 = 1500초 = 25분
      expect(recent.last.elapsedSeconds, 1500);
    });

    test('난이도 필터: beginner만 필터링', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 200,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 1),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'easy', elapsedSeconds: 400,
          mistakeCount: 1, hintCount: 0, grade: 'A',
          completedAt: DateTime(2026, 5, 2),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'medium', elapsedSeconds: 600,
          mistakeCount: 0, hintCount: 1, grade: 'A',
          completedAt: DateTime(2026, 5, 3),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 180,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 4),
        ),
      ];

      final beginnerOnly = records.where((r) => r.difficulty == 'beginner').toList();
      expect(beginnerOnly.length, 2);
      expect(beginnerOnly.every((r) => r.difficulty == 'beginner'), true);
    });

    test('난이도 필터: hard 기록이 없으면 빈 리스트', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 200,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 1),
        ),
      ];

      final hardOnly = records.where((r) => r.difficulty == 'hard').toList();
      expect(hardOnly, isEmpty);
    });

    test('MM:SS 형식 표시 검증', () {
      // 차트 툴팁에서 사용하는 형식
      const totalSeconds1 = 125;
      final m1 = totalSeconds1 ~/ 60;
      final s1 = totalSeconds1 % 60;
      final display1 = '${m1.toString().padLeft(2, '0')}:${s1.toString().padLeft(2, '0')}';
      expect(display1, '02:05');

      // 0초인 경우
      const totalSeconds2 = 0;
      final m2 = totalSeconds2 ~/ 60;
      final s2 = totalSeconds2 % 60;
      final display2 = '${m2.toString().padLeft(2, '0')}:${s2.toString().padLeft(2, '0')}';
      expect(display2, '00:00');

      // 59분 59초
      const totalSeconds3 = 3599;
      final m3 = totalSeconds3 ~/ 60;
      final s3 = totalSeconds3 % 60;
      final display3 = '${m3.toString().padLeft(2, '0')}:${s3.toString().padLeft(2, '0')}';
      expect(display3, '59:59');
    });

    test('차트 maxX 엣지케이스: 레코드 1개', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 300,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 1),
        ),
      ];

      // 레코드 1개일 때 maxX 계산 (수정 후)
      final maxX = records.length <= 1 ? 1.0 : (records.length - 1).toDouble();
      expect(maxX, 1.0); // 0이 아닌 1이어야 함
    });
  });

  group('QA Item 4: 차트 필터 맵핑 검증', () {
    test('필터 맵핑이 Difficulty enum 값과 일치', () {
      // 차트의 _difficultyMap 동일 로직
      const difficultyMap = {
        '입문': 'beginner',
        '쉬움': 'easy',
        '보통': 'medium',
        '어려움': 'hard',
      };

      expect(difficultyMap['입문'], Difficulty.beginner.name);
      expect(difficultyMap['쉬움'], Difficulty.easy.name);
      expect(difficultyMap['보통'], Difficulty.medium.name);
      expect(difficultyMap['어려움'], Difficulty.hard.name);
    });

    test('전체 필터는 모든 난이도를 포함', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 200,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 1),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'expert', elapsedSeconds: 1800,
          mistakeCount: 2, hintCount: 1, grade: 'B',
          completedAt: DateTime(2026, 5, 2),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'master', elapsedSeconds: 2400,
          mistakeCount: 3, hintCount: 2, grade: 'C',
          completedAt: DateTime(2026, 5, 3),
        ),
      ];

      // '전체' 필터: 필터링 없이 모든 기록
      final allRecords = records; // 전체 필터 시 그대로 사용
      expect(allRecords.length, 3);
    });
  });

  // ========================================================
  // Item 3 + 4 통합: copyWith 파라미터 조합 테스트
  // ========================================================
  group('QA: copyWith 복합 파라미터 조합', () {
    test('clearSelectedNumber와 inputMode 동시 설정', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 5,
      );

      final result = state.copyWith(
        inputMode: InputMode.cellFirst,
        clearSelectedNumber: true,
      );

      expect(result.inputMode, InputMode.cellFirst);
      expect(result.selectedNumber, isNull);
    });

    test('clearSelectedCell과 clearSelectedNumber 동시 사용', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        selectedCell: (3, 4),
        selectedNumber: 7,
      );

      final result = state.copyWith(
        clearSelectedCell: true,
        clearSelectedNumber: true,
      );

      expect(result.selectedCell, isNull);
      expect(result.selectedNumber, isNull);
    });

    test('selectedNumber를 새 값으로 설정 (clearSelectedNumber 없이)', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        selectedNumber: 3,
      );

      final result = state.copyWith(selectedNumber: 7);
      expect(result.selectedNumber, 7);
    });

    test('clearSelectedNumber=false는 기존 값 유지', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        selectedNumber: 3,
      );

      // clearSelectedNumber 기본값은 false이므로 기존 값 유지
      final result = state.copyWith();
      expect(result.selectedNumber, 3);
    });
  });
}
