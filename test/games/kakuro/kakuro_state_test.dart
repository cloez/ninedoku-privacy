import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/kakuro/engine/kakuro_board.dart';
import 'package:ninedoku/games/kakuro/kakuro_state.dart';

void main() {
  /// 테스트용 간단한 보드 생성
  KakuroBoard _makeBoard() {
    return KakuroBoard(
      rows: 3,
      cols: 3,
      cells: [
        const KakuroCell.black(),
        const KakuroCell.black(downHint: 5),
        const KakuroCell.black(downHint: 7),
        const KakuroCell.black(acrossHint: 3),
        const KakuroCell.white(value: 0),
        const KakuroCell.white(value: 0),
        const KakuroCell.black(acrossHint: 9),
        const KakuroCell.white(value: 0),
        const KakuroCell.white(value: 0),
      ],
    );
  }

  group('KakuroState', () {
    test('기본 상태 생성', () {
      final board = _makeBoard();
      final state = KakuroState(
        puzzle: board,
        solution: board,
        current: board,
        mode: KakuroGameMode.classic,
        difficulty: KakuroDifficulty.beginner,
      );

      expect(state.size, 3);
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
      final state = KakuroState(
        puzzle: board,
        solution: board,
        current: board,
        mode: KakuroGameMode.classic,
        difficulty: KakuroDifficulty.beginner,
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
      // 변경하지 않은 필드는 유지
      expect(updated.isCompleted, false);
      expect(updated.mode, KakuroGameMode.classic);
    });

    test('copyWith — 선택 셀 설정/해제', () {
      final board = _makeBoard();
      final state = KakuroState(
        puzzle: board,
        solution: board,
        current: board,
        mode: KakuroGameMode.classic,
        difficulty: KakuroDifficulty.beginner,
      );

      // 셀 선택
      final selected = state.copyWith(selectedCell: (1, 1));
      expect(selected.selectedCell, (1, 1));

      // 셀 선택 해제
      final cleared = selected.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, null);
    });

    test('copyWith — 힌트 대상 설정/해제', () {
      final board = _makeBoard();
      final state = KakuroState(
        puzzle: board,
        solution: board,
        current: board,
        mode: KakuroGameMode.classic,
        difficulty: KakuroDifficulty.beginner,
      );

      final withHint = state.copyWith(
        hintTargetCell: (2, 1),
        currentHintLevel: 1,
      );
      expect(withHint.hintTargetCell, (2, 1));
      expect(withHint.currentHintLevel, 1);

      final clearedHint = withHint.copyWith(
        clearHintTarget: true,
        currentHintLevel: 0,
      );
      expect(clearedHint.hintTargetCell, null);
      expect(clearedHint.currentHintLevel, 0);
    });

    test('JSON 직렬화/역직렬화', () {
      final board = _makeBoard();
      final state = KakuroState(
        puzzle: board,
        solution: board,
        current: board,
        mode: KakuroGameMode.classic,
        difficulty: KakuroDifficulty.beginner,
        elapsedSeconds: 60,
        mistakeCount: 1,
        hintCount: 2,
        selectedCell: (1, 2),
        isNoteMode: true,
      );

      final json = state.toJson();
      final restored = KakuroState.fromJson(json);

      expect(restored.mode, KakuroGameMode.classic);
      expect(restored.difficulty, KakuroDifficulty.beginner);
      expect(restored.elapsedSeconds, 60);
      expect(restored.mistakeCount, 1);
      expect(restored.hintCount, 2);
      expect(restored.selectedCell, (1, 2));
      expect(restored.isNoteMode, true);
    });

    test('등급 산정 — 퍼펙트', () {
      expect(
        KakuroGrade.evaluate(
          mistakes: 0,
          hints: 0,
          elapsedSeconds: 60,
          difficulty: KakuroDifficulty.beginner,
        ),
        KakuroGrade.perfect,
      );
    });

    test('등급 산정 — 훌륭함', () {
      expect(
        KakuroGrade.evaluate(
          mistakes: 1,
          hints: 0,
        ),
        KakuroGrade.excellent,
      );
    });

    test('등급 산정 — 좋음', () {
      expect(
        KakuroGrade.evaluate(
          mistakes: 2,
          hints: 2,
        ),
        KakuroGrade.great,
      );
    });

    test('등급 산정 — 보통', () {
      expect(
        KakuroGrade.evaluate(
          mistakes: 5,
          hints: 5,
        ),
        KakuroGrade.good,
      );
    });

    test('난이도별 기준 시간', () {
      expect(KakuroGrade.baseTimeForDifficulty(KakuroDifficulty.beginner), 120);
      expect(KakuroGrade.baseTimeForDifficulty(KakuroDifficulty.easy), 300);
      expect(KakuroGrade.baseTimeForDifficulty(KakuroDifficulty.medium), 600);
      expect(KakuroGrade.baseTimeForDifficulty(KakuroDifficulty.hard), 1200);
    });

    test('게임 모드 라벨', () {
      expect(KakuroGameMode.classic.label, '클래식');
      expect(KakuroGameMode.relax.label, '릴렉스');
      expect(KakuroGameMode.dailyPuzzle.label, '오늘의 퍼즐');
      expect(KakuroGameMode.challenge.label, '도전');
    });

    test('난이도 속성', () {
      expect(KakuroDifficulty.beginner.gridSize, 6);
      expect(KakuroDifficulty.easy.gridSize, 8);
      expect(KakuroDifficulty.medium.gridSize, 10);
      expect(KakuroDifficulty.hard.gridSize, 12);
      expect(KakuroDifficulty.beginner.code, 0);
      expect(KakuroDifficulty.hard.code, 3);
    });
  });
}
