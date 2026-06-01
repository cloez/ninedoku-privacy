import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/binairo/binairo_state.dart';
import 'package:ninedoku/games/binairo/engine/binairo_board.dart';
import 'package:ninedoku/games/binairo/engine/binairo_generator.dart';

/// 비나이로 상태 모델 테스트
void main() {
  // 테스트용 퍼즐/솔루션 쌍
  late BinairoBoard puzzle;
  late BinairoBoard solution;
  late BinairoBoard current;

  setUp(() {
    final result = BinairoGenerator.generate(
      size: 6,
      difficulty: 0,
      seed: 42,
    );
    puzzle = result!.puzzle;
    solution = result.solution;
    current = result.puzzle.copyWith();
  });

  // ════════════════════════════════════════════════════════════════════
  // BinairoState 기본 테스트
  // ════════════════════════════════════════════════════════════════════
  group('BinairoState 기본', () {
    test('생성 및 기본값 확인', () {
      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      expect(state.size, 6);
      expect(state.mode, BinairoGameMode.classic);
      expect(state.difficulty, BinairoDifficulty.beginner);
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.isAutoCompleting, false);
      expect(state.undoStack, isEmpty);
      expect(state.selectedCell, isNull);
      expect(state.currentHintLevel, 0);
      expect(state.hintTargetCell, isNull);
      expect(state.lastHintResult, isNull);
      expect(state.inputMode, BinairoInputMode.black);
    });

    test('copyWith로 각 필드 독립 변경', () {
      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      // 개별 필드 변경
      final updated = state.copyWith(
        elapsedSeconds: 100,
        mistakeCount: 2,
        hintCount: 1,
        isPaused: true,
        isCompleted: true,
        selectedCell: (3, 4),
        inputMode: BinairoInputMode.white,
      );

      expect(updated.elapsedSeconds, 100);
      expect(updated.mistakeCount, 2);
      expect(updated.hintCount, 1);
      expect(updated.isPaused, true);
      expect(updated.isCompleted, true);
      expect(updated.selectedCell, (3, 4));
      expect(updated.inputMode, BinairoInputMode.white);
      // 변경하지 않은 필드는 유지
      expect(updated.mode, BinairoGameMode.classic);
      expect(updated.difficulty, BinairoDifficulty.beginner);
    });

    test('copyWith clearSelectedCell 동작', () {
      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      ).copyWith(selectedCell: (1, 2));

      expect(state.selectedCell, (1, 2));

      final cleared = state.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, isNull);
    });

    test('copyWith clearHintTarget 동작', () {
      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      ).copyWith(hintTargetCell: (2, 3));

      expect(state.hintTargetCell, (2, 3));

      final cleared = state.copyWith(clearHintTarget: true);
      expect(cleared.hintTargetCell, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // JSON 직렬화/역직렬화 테스트
  // ════════════════════════════════════════════════════════════════════
  group('JSON 직렬화', () {
    test('toJson / fromJson 라운드트립 정합성', () {
      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.dailyPuzzle,
        difficulty: BinairoDifficulty.medium,
        elapsedSeconds: 245,
        mistakeCount: 1,
        hintCount: 2,
        isPaused: false,
        isCompleted: false,
        selectedCell: (4, 5),
        currentHintLevel: 2,
        hintTargetCell: (1, 3),
      );

      final json = state.toJson();
      final jsonStr = jsonEncode(json);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = BinairoState.fromJson(decoded);

      expect(restored.mode, BinairoGameMode.dailyPuzzle);
      expect(restored.difficulty, BinairoDifficulty.medium);
      expect(restored.elapsedSeconds, 245);
      expect(restored.mistakeCount, 1);
      expect(restored.hintCount, 2);
      expect(restored.isPaused, false);
      expect(restored.isCompleted, false);
      expect(restored.selectedCell, (4, 5));
      expect(restored.currentHintLevel, 2);
      expect(restored.hintTargetCell, (1, 3));
      // 보드 데이터 일치
      expect(restored.puzzle.cells, puzzle.cells);
      expect(restored.solution.cells, solution.cells);
      expect(restored.current.cells, current.cells);
    });

    test('모든 BinairoGameMode JSON 왕복', () {
      for (final mode in BinairoGameMode.values) {
        final state = BinairoState(
          puzzle: puzzle,
          solution: solution,
          current: current,
          mode: mode,
          difficulty: BinairoDifficulty.easy,
        );
        final restored = BinairoState.fromJson(state.toJson());
        expect(restored.mode, mode, reason: '모드 ${mode.name} JSON 왕복 실패');
      }
    });

    test('모든 BinairoDifficulty JSON 왕복', () {
      for (final diff in BinairoDifficulty.values) {
        final state = BinairoState(
          puzzle: puzzle,
          solution: solution,
          current: current,
          mode: BinairoGameMode.classic,
          difficulty: diff,
        );
        final restored = BinairoState.fromJson(state.toJson());
        expect(restored.difficulty, diff,
            reason: '난이도 ${diff.name} JSON 왕복 실패');
      }
    });

    test('selectedCell null인 상태 직렬화/역직렬화', () {
      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.relax,
        difficulty: BinairoDifficulty.beginner,
      );

      expect(state.selectedCell, isNull);

      final json = state.toJson();
      expect(json['selectedCell'], isNull);

      final restored = BinairoState.fromJson(json);
      expect(restored.selectedCell, isNull);
    });

    test('undoStack은 toJson에 포함되지 않음', () {
      final undoAction = BinairoUndoAction(
        type: BinairoUndoActionType.setValue,
        row: 0,
        col: 1,
        previousValue: -1,
      );

      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
        undoStack: [undoAction],
      );

      final json = state.toJson();
      // undoStack 키가 JSON에 없어야 함
      expect(json.containsKey('undoStack'), false);

      // 역직렬화하면 undoStack은 빈 리스트
      final restored = BinairoState.fromJson(json);
      expect(restored.undoStack, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // BinairoGrade 등급 산정 테스트
  // ════════════════════════════════════════════════════════════════════
  group('BinairoGrade 등급 산정', () {
    test('실수 0, 힌트 0, 시간 이내 → perfect (S)', () {
      final grade = BinairoGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 60,
        difficulty: BinairoDifficulty.beginner,
      );
      expect(grade, BinairoGrade.perfect);
    });

    test('실수 0, 힌트 0, 시간 초과 → excellent (A)', () {
      // beginner 기준 시간 120초, 2배인 240초 초과
      final grade = BinairoGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 300,
        difficulty: BinairoDifficulty.beginner,
      );
      // 노미스 노힌트면 시간 초과해도 최소 A
      expect(grade, BinairoGrade.excellent);
    });

    test('실수 1, 힌트 0 → excellent (A) (기본 임계값)', () {
      final grade = BinairoGrade.evaluate(
        mistakes: 1,
        hints: 0,
        difficulty: BinairoDifficulty.beginner,
      );
      expect(grade, BinairoGrade.excellent);
    });

    test('실수 2, 힌트 2 → great (B) (기본 임계값)', () {
      // 기본 임계값: bMistakes=1, bHints=1 초과하므로 B 이하
      // cMistakes=3, cHints=3 이내이므로 B
      final grade = BinairoGrade.evaluate(
        mistakes: 2,
        hints: 2,
        difficulty: BinairoDifficulty.beginner,
      );
      expect(grade, BinairoGrade.great);
    });

    test('대량 실수/힌트 → good (C)', () {
      final grade = BinairoGrade.evaluate(
        mistakes: 5,
        hints: 5,
        difficulty: BinairoDifficulty.beginner,
      );
      expect(grade, BinairoGrade.good);
    });

    test('상태에서 grade 속성 계산', () {
      final state = BinairoState(
        puzzle: puzzle,
        solution: solution,
        current: current,
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
        mistakeCount: 0,
        hintCount: 0,
      );
      expect(state.grade, BinairoGrade.perfect);

      final badState = state.copyWith(mistakeCount: 10, hintCount: 10);
      expect(badState.grade, BinairoGrade.good);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 난이도별 기준 시간 테스트
  // ════════════════════════════════════════════════════════════════════
  group('BinairoGrade 기준 시간', () {
    test('난이도별 기준 시간 확인', () {
      expect(BinairoGrade.baseTimeForDifficulty(BinairoDifficulty.beginner), 120);
      expect(BinairoGrade.baseTimeForDifficulty(BinairoDifficulty.easy), 240);
      expect(BinairoGrade.baseTimeForDifficulty(BinairoDifficulty.medium), 480);
      expect(BinairoGrade.baseTimeForDifficulty(BinairoDifficulty.hard), 720);
      expect(BinairoGrade.baseTimeForDifficulty(BinairoDifficulty.master), 1200);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Enum 값 테스트
  // ════════════════════════════════════════════════════════════════════
  group('Enum 값 확인', () {
    test('BinairoInputMode enum 값 확인', () {
      expect(BinairoInputMode.values.length, 3);
      expect(BinairoInputMode.values, contains(BinairoInputMode.black));
      expect(BinairoInputMode.values, contains(BinairoInputMode.white));
      expect(BinairoInputMode.values, contains(BinairoInputMode.erase));
    });

    test('BinairoGameMode 라벨 확인', () {
      expect(BinairoGameMode.classic.label, '클래식');
      expect(BinairoGameMode.relax.label, '릴렉스');
      expect(BinairoGameMode.dailyPuzzle.label, '오늘의 퍼즐');
      expect(BinairoGameMode.quickPlay.label, '빠른 게임');
      expect(BinairoGameMode.challenge.label, '도전');
    });

    test('BinairoDifficulty gridSize 및 라벨 확인', () {
      expect(BinairoDifficulty.beginner.gridSize, 6);
      expect(BinairoDifficulty.beginner.label, '입문');
      expect(BinairoDifficulty.easy.gridSize, 8);
      expect(BinairoDifficulty.easy.label, '쉬움');
      expect(BinairoDifficulty.medium.gridSize, 10);
      expect(BinairoDifficulty.hard.gridSize, 12);
      expect(BinairoDifficulty.master.gridSize, 14);
    });

    test('BinairoDifficulty code는 index와 동일', () {
      for (var i = 0; i < BinairoDifficulty.values.length; i++) {
        expect(BinairoDifficulty.values[i].code, i);
      }
    });
  });
}
