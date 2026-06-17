import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/skyscrapers/engine/skyscrapers_board.dart';
import 'package:ninedoku/games/skyscrapers/skyscrapers_state.dart';

void main() {
  /// 테스트용 간단한 보드 생성
  SkyscrapersBoard _makeBoard({
    int size = 4,
    List<int>? cells,
    Set<int>? fixed,
  }) {
    return SkyscrapersBoard(
      size: size,
      cells: cells ?? List<int>.filled(size * size, 0),
      topClues: List<int>.filled(size, 0),
      bottomClues: List<int>.filled(size, 0),
      leftClues: List<int>.filled(size, 0),
      rightClues: List<int>.filled(size, 0),
      fixed: fixed ?? {},
    );
  }

  group('SkyscrapersState', () {
    test('기본 상태 생성', () {
      final board = _makeBoard();
      final state = SkyscrapersState(
        puzzle: board,
        solution: board,
        current: board,
        mode: SkyscrapersGameMode.classic,
        difficulty: SkyscrapersDifficulty.beginner,
      );

      expect(state.size, 4);
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.isNoteMode, false);
      expect(state.selectedCell, null);
    });

    test('copyWith — 기본 필드 변경', () {
      final board = _makeBoard();
      final state = SkyscrapersState(
        puzzle: board,
        solution: board,
        current: board,
        mode: SkyscrapersGameMode.classic,
        difficulty: SkyscrapersDifficulty.beginner,
      );

      final updated = state.copyWith(
        elapsedSeconds: 120,
        mistakeCount: 2,
        hintCount: 1,
        isPaused: true,
      );

      expect(updated.elapsedSeconds, 120);
      expect(updated.mistakeCount, 2);
      expect(updated.hintCount, 1);
      expect(updated.isPaused, true);
    });

    test('copyWith — 선택 셀 설정/해제', () {
      final board = _makeBoard();
      final state = SkyscrapersState(
        puzzle: board,
        solution: board,
        current: board,
        mode: SkyscrapersGameMode.classic,
        difficulty: SkyscrapersDifficulty.beginner,
      );

      final selected = state.copyWith(selectedCell: (1, 2));
      expect(selected.selectedCell, (1, 2));

      final cleared = selected.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, null);
    });

    test('copyWith — 메모 모드 토글', () {
      final board = _makeBoard();
      final state = SkyscrapersState(
        puzzle: board,
        solution: board,
        current: board,
        mode: SkyscrapersGameMode.classic,
        difficulty: SkyscrapersDifficulty.beginner,
      );

      final noteMode = state.copyWith(isNoteMode: true);
      expect(noteMode.isNoteMode, true);

      final normalMode = noteMode.copyWith(isNoteMode: false);
      expect(normalMode.isNoteMode, false);
    });

    test('JSON 직렬화/역직렬화', () {
      final board = _makeBoard(
        cells: [1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        fixed: {0, 1, 2, 3},
      );

      final state = SkyscrapersState(
        puzzle: board,
        solution: board,
        current: board,
        mode: SkyscrapersGameMode.classic,
        difficulty: SkyscrapersDifficulty.beginner,
        elapsedSeconds: 60,
        mistakeCount: 1,
        hintCount: 0,
        selectedCell: (2, 3),
        isNoteMode: true,
      );

      final json = state.toJson();
      final restored = SkyscrapersState.fromJson(json);

      expect(restored.mode, SkyscrapersGameMode.classic);
      expect(restored.difficulty, SkyscrapersDifficulty.beginner);
      expect(restored.elapsedSeconds, 60);
      expect(restored.mistakeCount, 1);
      expect(restored.hintCount, 0);
      expect(restored.selectedCell, (2, 3));
      expect(restored.isNoteMode, true);
      expect(restored.current.getValue(0, 0), 1);
    });

    test('JSON — selectedCell이 null인 경우', () {
      final board = _makeBoard();
      final state = SkyscrapersState(
        puzzle: board,
        solution: board,
        current: board,
        mode: SkyscrapersGameMode.dailyPuzzle,
        difficulty: SkyscrapersDifficulty.medium,
      );

      final json = state.toJson();
      final restored = SkyscrapersState.fromJson(json);

      expect(restored.selectedCell, null);
      expect(restored.mode, SkyscrapersGameMode.dailyPuzzle);
      expect(restored.difficulty, SkyscrapersDifficulty.medium);
    });
  });

  group('SkyscrapersGrade', () {
    test('퍼펙트 등급 — 실수 0, 힌트 0, 시간 이내', () {
      final grade = SkyscrapersGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 30,
        difficulty: SkyscrapersDifficulty.beginner,
      );
      expect(grade, SkyscrapersGrade.perfect);
    });

    test('A등급 — 실수 0, 힌트 0, 시간 초과', () {
      final grade = SkyscrapersGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 120,
        difficulty: SkyscrapersDifficulty.beginner,
      );
      expect(grade, SkyscrapersGrade.excellent);
    });

    test('B등급 — 실수 또는 힌트 1', () {
      final grade = SkyscrapersGrade.evaluate(
        mistakes: 1,
        hints: 0,
      );
      expect(grade, SkyscrapersGrade.excellent);
    });

    test('C등급 — 실수 4', () {
      final grade = SkyscrapersGrade.evaluate(
        mistakes: 4,
        hints: 0,
      );
      expect(grade, SkyscrapersGrade.good);
    });
  });

  group('SkyscrapersDifficulty', () {
    test('난이도별 격자 크기', () {
      expect(SkyscrapersDifficulty.beginner.gridSize, 4);
      expect(SkyscrapersDifficulty.easy.gridSize, 5);
      expect(SkyscrapersDifficulty.medium.gridSize, 6);
      expect(SkyscrapersDifficulty.hard.gridSize, 7);
      expect(SkyscrapersDifficulty.master.gridSize, 8);
    });

    test('난이도 코드', () {
      expect(SkyscrapersDifficulty.beginner.code, 0);
      expect(SkyscrapersDifficulty.easy.code, 1);
      expect(SkyscrapersDifficulty.medium.code, 2);
      expect(SkyscrapersDifficulty.hard.code, 3);
      expect(SkyscrapersDifficulty.master.code, 4);
    });

    test('기준 시간', () {
      expect(SkyscrapersGrade.baseTimeForDifficulty(SkyscrapersDifficulty.beginner), 60);
      expect(SkyscrapersGrade.baseTimeForDifficulty(SkyscrapersDifficulty.easy), 120);
      expect(SkyscrapersGrade.baseTimeForDifficulty(SkyscrapersDifficulty.medium), 300);
      expect(SkyscrapersGrade.baseTimeForDifficulty(SkyscrapersDifficulty.hard), 600);
      expect(SkyscrapersGrade.baseTimeForDifficulty(SkyscrapersDifficulty.master), 1200);
    });
  });
}
