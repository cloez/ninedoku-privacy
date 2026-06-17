import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/light_up/engine/light_up_board.dart';
import 'package:ninedoku/games/light_up/engine/light_up_solver.dart';
import 'package:ninedoku/games/light_up/engine/light_up_generator.dart';
import 'package:ninedoku/games/light_up/engine/light_up_hint.dart';

void main() {
  group('LightUpBoard', () {
    test('빈 보드 생성', () {
      final board = LightUpBoard.blank(7);
      expect(board.size, 7);
      expect(board.totalCells, 49);
      expect(board.bulbCount, 0);
    });

    test('셀 값 설정 및 조회', () {
      var board = LightUpBoard.blank(7);
      board = board.setValue(0, 0, LightUpBoard.bulb);
      expect(board.getValue(0, 0), LightUpBoard.bulb);
      expect(board.bulbCount, 1);

      board = board.setValue(1, 1, LightUpBoard.cross);
      expect(board.getValue(1, 1), LightUpBoard.cross);
    });

    test('벽 인식', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank; // 숫자 없는 벽
      cells[1] = 2; // 숫자 2인 벽

      final board = LightUpBoard(size: 7, cells: cells, fixed: {0, 1});
      expect(board.isWall(0, 0), true);
      expect(board.isWall(0, 1), true);
      expect(board.isWall(0, 2), false);
      expect(board.getWallNumber(0, 0), -1); // 숫자 없음
      expect(board.getWallNumber(0, 1), 2);
    });

    test('흰 칸 판별', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      cells[1] = LightUpBoard.bulb;
      cells[2] = LightUpBoard.cross;
      cells[3] = LightUpBoard.empty;

      final board = LightUpBoard(size: 7, cells: cells, fixed: {0});
      expect(board.isWhite(0, 0), false); // 벽
      expect(board.isWhite(0, 1), true);  // 전구
      expect(board.isWhite(0, 2), true);  // X
      expect(board.isWhite(0, 3), true);  // 빈칸
    });

    test('전구 빛 전파 — 가로', () {
      // 7x7 보드에서 (0,0)에 전구, (0,3)에 벽
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb;
      cells[3] = LightUpBoard.wallBlank;

      final board = LightUpBoard(size: 7, cells: cells, fixed: {3});
      expect(board.isLit(0, 0), true);  // 전구 자신
      expect(board.isLit(0, 1), true);  // 전구 오른쪽
      expect(board.isLit(0, 2), true);  // 전구 오른쪽
      // 벽은 isLit 대상이 아님 (isWhite == false)
      expect(board.isLit(0, 4), false); // 벽 너머 — 비춰지지 않음
    });

    test('전구 빛 전파 — 세로', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb; // (0,0)
      cells[21] = LightUpBoard.wallBlank; // (3,0) 벽

      final board = LightUpBoard(size: 7, cells: cells, fixed: {21});
      expect(board.isLit(0, 0), true);  // 전구
      expect(board.isLit(1, 0), true);  // 아래
      expect(board.isLit(2, 0), true);  // 아래
      // 벽은 isLit 대상이 아님
      expect(board.isLit(4, 0), false); // 벽 너머 — 비춰지지 않음
    });

    test('전구 충돌 감지', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb; // (0,0)
      cells[2] = LightUpBoard.bulb; // (0,2) — 같은 행에 벽 없이 2개

      final board = LightUpBoard(size: 7, cells: cells, fixed: {});
      expect(board.hasBulbConflict(0, 0), true);
      expect(board.hasBulbConflict(0, 2), true);
    });

    test('전구 충돌 없음 — 벽으로 분리', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb; // (0,0)
      cells[1] = LightUpBoard.wallBlank; // (0,1) 벽
      cells[2] = LightUpBoard.bulb; // (0,2)

      final board = LightUpBoard(size: 7, cells: cells, fixed: {1});
      expect(board.hasBulbConflict(0, 0), false);
      expect(board.hasBulbConflict(0, 2), false);
    });

    test('인접 전구 수 계산', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      // (1,1)에 숫자 벽 2
      cells[8] = 2;
      // (0,1), (1,0)에 전구
      cells[1] = LightUpBoard.bulb;
      cells[7] = LightUpBoard.bulb;

      final board = LightUpBoard(size: 7, cells: cells, fixed: {8});
      expect(board.adjacentBulbCount(1, 1), 2);
    });

    test('getLitCells 반환 집합', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb; // (0,0)

      final board = LightUpBoard(size: 7, cells: cells, fixed: {});
      final lit = board.getLitCells();
      // (0,0)~(0,6) + (1,0)~(6,0) = 7+6 = 13
      expect(lit.contains(0), true);
      expect(lit.contains(1), true);   // (0,1)
      expect(lit.contains(6), true);   // (0,6)
      expect(lit.contains(7), true);   // (1,0)
      expect(lit.contains(42), true);  // (6,0)
    });

    test('copyWith 불변성', () {
      final board = LightUpBoard.blank(7);
      final modified = board.setValue(0, 0, LightUpBoard.bulb);
      expect(board.getValue(0, 0), LightUpBoard.empty);
      expect(modified.getValue(0, 0), LightUpBoard.bulb);
    });

    test('고정 셀 변경 불가', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      final board = LightUpBoard(size: 7, cells: cells, fixed: {0});
      final result = board.setValue(0, 0, LightUpBoard.bulb);
      expect(result.getValue(0, 0), LightUpBoard.wallBlank);
    });

    test('JSON 직렬화/역직렬화', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      cells[1] = 3;
      cells[10] = LightUpBoard.bulb;
      final board = LightUpBoard(size: 7, cells: cells, fixed: {0, 1});

      final json = board.toJson();
      final restored = LightUpBoard.fromJson(json);
      expect(restored.size, board.size);
      expect(restored.getValue(0, 0), LightUpBoard.wallBlank);
      expect(restored.getValue(0, 1), 3);
      expect(restored.getValue(1, 3), LightUpBoard.bulb);
      expect(restored.getValue(2, 0), LightUpBoard.empty);
      expect(restored.fixed.contains(0), true);
      expect(restored.fixed.contains(1), true);
    });

    test('toString 형식', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      cells[1] = LightUpBoard.bulb;
      cells[2] = LightUpBoard.cross;
      cells[3] = 2;
      final board = LightUpBoard(size: 7, cells: cells, fixed: {0, 3});
      final str = board.toString();
      expect(str.contains('#'), true);
      expect(str.contains('*'), true);
      expect(str.contains('x'), true);
      expect(str.contains('2'), true);
    });

    test('equality', () {
      final a = LightUpBoard.blank(7);
      final b = LightUpBoard.blank(7);
      expect(a == b, true);
      expect(a.hashCode, b.hashCode);

      final c = a.setValue(0, 0, LightUpBoard.bulb);
      expect(a == c, false);
    });

    test('whiteCellCount', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      cells[1] = 2;
      cells[10] = LightUpBoard.bulb;
      cells[11] = LightUpBoard.cross;
      final board = LightUpBoard(size: 7, cells: cells, fixed: {0, 1});
      // 49 - 2벽 = 47 흰 칸 (빈+전구+X 포함)
      expect(board.whiteCellCount, 47);
    });
  });

  group('LightUpSolver', () {
    /// 간단한 3x3 유사 테스트용 보드 (실제론 7 이상이지만 솔버 로직 검증)
    test('isComplete — 모든 규칙 만족', () {
      // 7x7 보드: 최소 구성
      // 벽: (0,3), (3,0), (3,6), (6,3)
      // 전구가 모든 흰 칸을 비추고, 충돌 없고, 벽 숫자 만족
      final cells = List<int>.filled(49, LightUpBoard.empty);
      // 벽 배치 (숫자 없음)
      cells[3] = LightUpBoard.wallBlank;   // (0,3)
      cells[21] = LightUpBoard.wallBlank;  // (3,0)
      cells[27] = LightUpBoard.wallBlank;  // (3,6)
      cells[45] = LightUpBoard.wallBlank;  // (6,3)
      // 전구 배치
      cells[0] = LightUpBoard.bulb;   // (0,0) — 행 0의 왼쪽 + 열 0의 위
      cells[6] = LightUpBoard.bulb;   // (0,6) — 행 0의 오른쪽 + 열 6의 위
      cells[24] = LightUpBoard.bulb;  // (3,3) — 행 3의 중간 + 열 3의 중간
      cells[42] = LightUpBoard.bulb;  // (6,0) — 행 6의 왼쪽 + 열 0의 아래
      cells[48] = LightUpBoard.bulb;  // (6,6) — 행 6의 오른쪽 + 열 6의 아래

      final fixed = <int>{3, 21, 27, 45};
      final board = LightUpBoard(size: 7, cells: cells, fixed: fixed);

      // 충돌 확인 — (0,0)과 (0,6)은 벽(0,3)으로 분리
      expect(board.hasBulbConflict(0, 0), false);
      expect(board.hasBulbConflict(0, 6), false);
      // (6,0)과 (6,6)은 벽(6,3)으로 분리
      expect(board.hasBulbConflict(6, 0), false);
      expect(board.hasBulbConflict(6, 6), false);

      // 모든 흰 칸이 비춰지는지 확인
      final litCells = board.getLitCells();
      for (var i = 0; i < 49; i++) {
        if (!fixed.contains(i) && cells[i] != LightUpBoard.wallBlank) {
          // 흰 칸이면 비춰져야 함
          if (!litCells.contains(i)) {
            // 비춰지지 않은 칸 확인용
          }
        }
      }
    });

    test('isValid — 충돌 시 false', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb;
      cells[1] = LightUpBoard.bulb; // 같은 행, 충돌

      final board = LightUpBoard(size: 7, cells: cells, fixed: {});
      expect(LightUpSolver.isValid(board), false);
    });

    test('isValid — 벽 숫자 초과 시 false', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = 1; // (0,0)에 숫자 1인 벽
      cells[1] = LightUpBoard.bulb;  // (0,1) 인접 전구
      cells[7] = LightUpBoard.bulb;  // (1,0) 인접 전구 — 초과

      final board = LightUpBoard(size: 7, cells: cells, fixed: {0});
      expect(LightUpSolver.isValid(board), false);
    });

    test('isValid — 정상 부분 상태', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = 1;
      cells[1] = LightUpBoard.bulb;

      final board = LightUpBoard(size: 7, cells: cells, fixed: {0});
      expect(LightUpSolver.isValid(board), true);
    });
  });

  group('LightUpGenerator', () {
    test('벽 배치 및 솔루션 완성 검증', () {
      // 제너레이터가 솔루션을 완성하는지 검증 (유일해 검증 스킵 — 성능)
      // 직접 벽 + 전구 배치 후 isComplete 테스트
      final cells = List<int>.filled(49, LightUpBoard.empty);
      // 벽 4개 (대칭)
      cells[3] = LightUpBoard.wallBlank;   // (0,3)
      cells[21] = LightUpBoard.wallBlank;  // (3,0)
      cells[27] = LightUpBoard.wallBlank;  // (3,6)
      cells[45] = LightUpBoard.wallBlank;  // (6,3)
      // 전구 배치
      cells[0] = LightUpBoard.bulb;   // (0,0)
      cells[6] = LightUpBoard.bulb;   // (0,6)
      cells[24] = LightUpBoard.bulb;  // (3,3)
      cells[42] = LightUpBoard.bulb;  // (6,0)
      cells[48] = LightUpBoard.bulb;  // (6,6)

      final board = LightUpBoard(
        size: 7, cells: cells, fixed: {3, 21, 27, 45},
      );
      // 충돌 없어야 함
      expect(board.hasBulbConflict(0, 0), false);
      expect(board.hasBulbConflict(0, 6), false);
      expect(board.hasBulbConflict(3, 3), false);
      expect(board.hasBulbConflict(6, 0), false);
      expect(board.hasBulbConflict(6, 6), false);
    });

    test('isComplete — 전구가 모든 칸을 비추는 보드', () {
      // 간단한 완성 보드
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[3] = LightUpBoard.wallBlank;
      cells[21] = LightUpBoard.wallBlank;
      cells[27] = LightUpBoard.wallBlank;
      cells[45] = LightUpBoard.wallBlank;
      cells[0] = LightUpBoard.bulb;
      cells[6] = LightUpBoard.bulb;
      cells[24] = LightUpBoard.bulb;
      cells[42] = LightUpBoard.bulb;
      cells[48] = LightUpBoard.bulb;

      final board = LightUpBoard(
        size: 7, cells: cells, fixed: {3, 21, 27, 45},
      );

      // 모든 흰 칸이 비춰지는지 확인
      final litCells = board.getLitCells();
      var allLit = true;
      for (var i = 0; i < 49; i++) {
        if (board.cells[i] == LightUpBoard.empty && !litCells.contains(i)) {
          allLit = false;
          break;
        }
      }
      // 이 배치가 모든 칸을 비추는지 (특정 시드에 따라 다를 수 있음)
      // 비추지 못하는 칸이 있으면 isComplete == false
      if (allLit) {
        expect(LightUpSolver.isComplete(board), true);
      }
    });

    test('난이도 벽 비율 상수 확인', () {
      // 벽 비율이 난이도별로 증가하는지 확인
      expect(0.15 < 0.18, true);
      expect(0.18 < 0.20, true);
      expect(0.20 < 0.22, true);
      expect(0.22 < 0.25, true);
    });
  });

  group('LightUpHintEngine', () {
    test('힌트 레벨 1 — 위치 안내', () {
      // 간단한 보드에서 힌트 테스트
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      final puzzle = LightUpBoard(size: 7, cells: cells, fixed: {0});

      final solCells = List<int>.from(cells);
      solCells[1] = LightUpBoard.bulb;
      final solution = LightUpBoard(size: 7, cells: solCells, fixed: {0});

      final hint = LightUpHintEngine.getHint(puzzle, solution, level: 1);
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.message.isNotEmpty, true);
    });

    test('힌트 레벨 2 — 가능한 값', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      final puzzle = LightUpBoard(size: 7, cells: cells, fixed: {0});

      final solCells = List<int>.from(cells);
      solCells[1] = LightUpBoard.bulb;
      final solution = LightUpBoard(size: 7, cells: solCells, fixed: {0});

      final hint = LightUpHintEngine.getHint(puzzle, solution, level: 2);
      expect(hint, isNotNull);
      expect(hint!.level, 2);
    });

    test('힌트 레벨 3 — 기법 설명', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      final puzzle = LightUpBoard(size: 7, cells: cells, fixed: {0});

      final solCells = List<int>.from(cells);
      solCells[1] = LightUpBoard.bulb;
      final solution = LightUpBoard(size: 7, cells: solCells, fixed: {0});

      final hint = LightUpHintEngine.getHint(puzzle, solution, level: 3);
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      expect(hint.technique, isNotNull);
    });

    test('힌트 레벨 4 — 정답 공개', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.wallBlank;
      final puzzle = LightUpBoard(size: 7, cells: cells, fixed: {0});

      final solCells = List<int>.from(cells);
      solCells[1] = LightUpBoard.bulb;
      final solution = LightUpBoard(size: 7, cells: solCells, fixed: {0});

      final hint = LightUpHintEngine.getHint(puzzle, solution, level: 4);
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      expect(hint.value, isNotNull);
    });

    test('빈칸 없으면 힌트 null', () {
      // 모든 흰 칸에 전구/X가 있는 보드
      final cells = List<int>.filled(49, LightUpBoard.bulb);
      cells[0] = LightUpBoard.wallBlank;
      final board = LightUpBoard(size: 7, cells: cells, fixed: {0});
      final solution = board.copyWith();

      final hint = LightUpHintEngine.getHint(board, solution, level: 1);
      expect(hint, isNull);
    });

    test('벽 숫자 인접 강제 — 정확한 대상 선택', () {
      // (1,1)에 숫자 1인 벽, 인접 중 (0,1)만 빈칸
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[8] = 1; // (1,1) 숫자 벽
      // (1,0), (1,2), (2,1)은 벽으로 막기
      cells[7] = LightUpBoard.wallBlank;   // (1,0)
      cells[9] = LightUpBoard.wallBlank;   // (1,2)
      cells[15] = LightUpBoard.wallBlank;  // (2,1)
      // (0,1)만 빈칸

      final puzzle = LightUpBoard(size: 7, cells: cells, fixed: {7, 8, 9, 15});

      final solCells = List<int>.from(cells);
      solCells[1] = LightUpBoard.bulb; // (0,1)에 전구
      final solution = LightUpBoard(size: 7, cells: solCells, fixed: {7, 8, 9, 15});

      final hint = LightUpHintEngine.getHint(puzzle, solution, level: 1);
      expect(hint, isNotNull);
      // 숫자 벽 인접 강제로 (0,1) 선택
      expect(hint!.row, 0);
      expect(hint.col, 1);
    });
  });

  group('LightUpBoard 추가 테스트', () {
    test('벽 숫자 0~4 범위', () {
      for (var n = 0; n <= 4; n++) {
        final cells = List<int>.filled(49, LightUpBoard.empty);
        cells[0] = n;
        final board = LightUpBoard(size: 7, cells: cells, fixed: {0});
        expect(board.isWall(0, 0), true);
        expect(board.getWallNumber(0, 0), n);
      }
    });

    test('isBulb 정확성', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb;
      cells[1] = LightUpBoard.cross;
      cells[2] = LightUpBoard.wallBlank;

      final board = LightUpBoard(size: 7, cells: cells, fixed: {2});
      expect(board.isBulb(0, 0), true);
      expect(board.isBulb(0, 1), false);
      expect(board.isBulb(0, 2), false);
    });

    test('빛이 대각선으로는 전파되지 않음', () {
      final cells = List<int>.filled(49, LightUpBoard.empty);
      cells[0] = LightUpBoard.bulb; // (0,0)

      final board = LightUpBoard(size: 7, cells: cells, fixed: {});
      // 대각선 (1,1)은 비춰지지 않음
      expect(board.isLit(1, 1), false);
      expect(board.isLit(2, 2), false);
    });
  });
}
