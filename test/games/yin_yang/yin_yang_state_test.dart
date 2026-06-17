import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/yin_yang/engine/yin_yang_board.dart';
import 'package:ninedoku/games/yin_yang/yin_yang_state.dart';

void main() {
  late YinYangState state;

  setUp(() {
    final board = YinYangBoard.empty(5);
    state = YinYangState(
      puzzle: board, solution: board, current: board,
      mode: YinYangGameMode.classic, difficulty: YinYangDifficulty.beginner,
    );
  });

  group('B. YinYangState', () {
    test('기본값 초기화', () {
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.inputMode, YinYangInputMode.black);
    });

    test('copyWith 동작', () {
      final updated = state.copyWith(elapsedSeconds: 60, isPaused: true);
      expect(updated.elapsedSeconds, 60);
      expect(updated.isPaused, true);
      expect(state.elapsedSeconds, 0); // 원본 불변
    });

    test('clearSelectedCell', () {
      final s1 = state.copyWith(selectedCell: (1, 2));
      final s2 = s1.copyWith(clearSelectedCell: true);
      expect(s2.selectedCell, isNull);
    });

    test('toJson / fromJson 라운드트립', () {
      final updated = state.copyWith(
        elapsedSeconds: 120, mistakeCount: 1, isPaused: true,
        selectedCell: (2, 3), inputMode: YinYangInputMode.white,
      );
      final json = updated.toJson();
      final restored = YinYangState.fromJson(json);
      expect(restored.elapsedSeconds, 120);
      expect(restored.mistakeCount, 1);
      expect(restored.selectedCell, (2, 3));
      expect(restored.inputMode, YinYangInputMode.white);
    });

    test('GameMode enum JSON 왕복', () {
      for (final mode in YinYangGameMode.values) {
        final s = state.copyWith(mode: mode);
        final restored = YinYangState.fromJson(s.toJson());
        expect(restored.mode, mode);
      }
    });

    test('Difficulty enum', () {
      for (final d in YinYangDifficulty.values) {
        expect(d.gridSize, greaterThan(0));
        expect(d.code, d.index);
      }
    });

    test('InputMode enum JSON 왕복', () {
      for (final mode in YinYangInputMode.values) {
        final s = state.copyWith(inputMode: mode);
        final restored = YinYangState.fromJson(s.toJson());
        expect(restored.inputMode, mode);
      }
    });

    test('등급 S (노미스 노힌트 기준시간이내)', () {
      final s = state.copyWith(elapsedSeconds: 30, mistakeCount: 0, hintCount: 0);
      expect(s.grade, YinYangGrade.perfect);
    });

    test('등급 C (실수 많음)', () {
      final s = state.copyWith(mistakeCount: 5, hintCount: 5);
      expect(s.grade, YinYangGrade.good);
    });

    test('등급 B', () {
      final s = state.copyWith(mistakeCount: 2, hintCount: 2);
      expect(s.grade, YinYangGrade.great);
    });

    test('난이도별 기준시간', () {
      expect(YinYangGrade.baseTimeForDifficulty(YinYangDifficulty.beginner), 60);
      expect(YinYangGrade.baseTimeForDifficulty(YinYangDifficulty.master), 1500);
    });

    test('size getter', () {
      expect(state.size, 5);
    });
  });
}
