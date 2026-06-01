import 'difficulty.dart';

/// 풀이 기법 종류
enum SolvingTechnique {
  nakedSingle('네이키드 싱글', '후보가 하나뿐인 셀'),
  hiddenSingle('히든 싱글', '영역 내 유일한 위치의 숫자'),
  nakedPair('네이키드 페어', '두 셀의 후보가 동일한 쌍'),
  hiddenPair('히든 페어', '영역 내 두 숫자가 같은 두 셀에만 존재'),
  pointingPair('포인팅 페어', '박스 내 후보가 한 행/열에만 존재'),
  boxLineReduction('박스/라인 축소', '행/열의 후보가 한 박스에만 존재'),
  nakedTriple('네이키드 트리플', '세 셀의 후보가 세 숫자의 부분집합'),
  xWing('X-Wing', '두 행/열에서 후보가 같은 두 위치에만 존재');

  const SolvingTechnique(this.label, this.description);
  final String label;
  final String description;

  /// 기법 난이도 점수
  int get score {
    switch (this) {
      case nakedSingle:
        return 1;
      case hiddenSingle:
        return 2;
      case nakedPair:
        return 4;
      case hiddenPair:
        return 5;
      case pointingPair:
        return 4;
      case boxLineReduction:
        return 5;
      case nakedTriple:
        return 6;
      case xWing:
        return 8;
    }
  }
}

/// 풀이 기법 적용 결과
class TechniqueResult {
  final SolvingTechnique technique;
  final int row;
  final int col;
  final int? value; // 값이 확정되는 기법인 경우
  final Set<int> eliminations; // 제거 가능한 후보
  final String explanation; // 설명 메시지

  const TechniqueResult({
    required this.technique,
    required this.row,
    required this.col,
    this.value,
    this.eliminations = const {},
    required this.explanation,
  });
}

/// 스도쿠 풀이 기법 분석기
class TechniqueAnalyzer {
  /// 보드를 풀이 기법만으로 분석하여 사용된 기법 목록 반환
  static List<SolvingTechnique> analyze(List<List<int>> puzzle) {
    final board = _copyBoard(puzzle);
    final candidates = _initCandidates(board);
    final usedTechniques = <SolvingTechnique>{};

    var progress = true;
    var iterations = 0;
    const maxIterations = 200;

    while (progress && iterations < maxIterations) {
      progress = false;
      iterations++;

      // 1. Naked Single
      if (_applyNakedSingle(board, candidates)) {
        usedTechniques.add(SolvingTechnique.nakedSingle);
        progress = true;
        continue;
      }

      // 2. Hidden Single
      if (_applyHiddenSingle(board, candidates)) {
        usedTechniques.add(SolvingTechnique.hiddenSingle);
        progress = true;
        continue;
      }

      // 3. Naked Pair
      if (_applyNakedPair(candidates)) {
        usedTechniques.add(SolvingTechnique.nakedPair);
        progress = true;
        continue;
      }

      // 4. Pointing Pair
      if (_applyPointingPair(candidates)) {
        usedTechniques.add(SolvingTechnique.pointingPair);
        progress = true;
        continue;
      }

      // 5. Box/Line Reduction
      if (_applyBoxLineReduction(candidates)) {
        usedTechniques.add(SolvingTechnique.boxLineReduction);
        progress = true;
        continue;
      }

      // 6. Hidden Pair
      if (_applyHiddenPair(candidates)) {
        usedTechniques.add(SolvingTechnique.hiddenPair);
        progress = true;
        continue;
      }

      // 7. Naked Triple
      if (_applyNakedTriple(candidates)) {
        usedTechniques.add(SolvingTechnique.nakedTriple);
        progress = true;
        continue;
      }

      // 8. X-Wing
      if (_applyXWing(candidates)) {
        usedTechniques.add(SolvingTechnique.xWing);
        progress = true;
        continue;
      }
    }

    return usedTechniques.toList();
  }

  /// 기법 기반 난이도 평가
  static Difficulty evaluateDifficulty(List<List<int>> puzzle) {
    final techniques = analyze(puzzle);
    if (techniques.isEmpty) {
      // 기법만으로 풀 수 없으면 빈 칸 기반 fallback
      return DifficultyEvaluator.evaluate(puzzle);
    }

    final maxScore = techniques.map((t) => t.score).reduce((a, b) => a > b ? a : b);
    final totalScore = techniques.fold<int>(0, (sum, t) => sum + t.score);

    // 최고 난이도 기법 + 총 점수로 분류
    // 마스터: X-Wing 사용 OR 복합 고급 기법 조합(Naked Triple급 + 높은 총점)
    if (maxScore >= 8) return Difficulty.master;
    if (maxScore >= 6 && totalScore >= 30) return Difficulty.master;
    if (maxScore >= 6 || totalScore >= 25) return Difficulty.expert;
    if (maxScore >= 4 || totalScore >= 15) return Difficulty.hard;
    if (maxScore >= 2 || totalScore >= 8) return Difficulty.medium;
    if (totalScore >= 4) return Difficulty.easy;
    return Difficulty.beginner;
  }

  /// 현재 보드 상태에서 적용 가능한 첫 번째 기법 찾기 (힌트용)
  static TechniqueResult? findNextTechnique(List<List<int>> currentBoard) {
    final candidates = _initCandidates(currentBoard);

    // Naked Single 검색
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (currentBoard[r][c] == 0 && candidates[r][c].length == 1) {
          final value = candidates[r][c].first;
          return TechniqueResult(
            technique: SolvingTechnique.nakedSingle,
            row: r,
            col: c,
            value: value,
            explanation: '이 셀에 들어갈 수 있는 숫자가 $value 하나뿐입니다.',
          );
        }
      }
    }

    // Hidden Single 검색
    final hiddenResult = _findHiddenSingle(currentBoard, candidates);
    if (hiddenResult != null) return hiddenResult;

    // Naked Pair 검색
    final pairResult = _findNakedPair(candidates);
    if (pairResult != null) return pairResult;

    // Pointing Pair 검색
    final pointingResult = _findPointingPair(candidates);
    if (pointingResult != null) return pointingResult;

    // Box/Line Reduction 검색
    final boxLineResult = _findBoxLineReduction(candidates);
    if (boxLineResult != null) return boxLineResult;

    // Hidden Pair 검색
    final hiddenPairResult = _findHiddenPair(candidates);
    if (hiddenPairResult != null) return hiddenPairResult;

    // Naked Triple 검색
    final tripleResult = _findNakedTriple(candidates);
    if (tripleResult != null) return tripleResult;

    // X-Wing 검색
    final xWingResult = _findXWing(candidates);
    if (xWingResult != null) return xWingResult;

    return null;
  }

  /// 특정 셀을 풀기 위해 필요한 최소 기법 판별 (추임새용)
  /// 보드를 단계적으로 풀면서 해당 셀이 어떤 기법으로 확정되는지 추적
  static SolvingTechnique? findTechniqueForCell(
    List<List<int>> currentBoard, int targetRow, int targetCol,
  ) {
    if (currentBoard[targetRow][targetCol] != 0) return null;

    final board = _copyBoard(currentBoard);
    final candidates = _initCandidates(board);
    var iterations = 0;
    const maxIterations = 200;

    while (iterations < maxIterations) {
      iterations++;

      // 1. Naked Single — 대상 셀이면 반환
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board[r][c] == 0 && candidates[r][c].length == 1) {
            if (r == targetRow && c == targetCol) return SolvingTechnique.nakedSingle;
            _placeValue(board, candidates, r, c, candidates[r][c].first);
          }
        }
      }
      if (board[targetRow][targetCol] != 0) return SolvingTechnique.nakedSingle;

      // 2. Hidden Single
      final hidden = _findHiddenSingleForCell(board, candidates, targetRow, targetCol);
      if (hidden != null) return hidden;
      if (_applyHiddenSingle(board, candidates)) continue;

      // 3~8. 고급 기법: 후보 제거 후 Naked Single로 확정되면 해당 기법 반환
      if (_applyNakedPair(candidates)) {
        if (candidates[targetRow][targetCol].length == 1) return SolvingTechnique.nakedPair;
        continue;
      }
      if (_applyPointingPair(candidates)) {
        if (candidates[targetRow][targetCol].length == 1) return SolvingTechnique.pointingPair;
        continue;
      }
      if (_applyBoxLineReduction(candidates)) {
        if (candidates[targetRow][targetCol].length == 1) return SolvingTechnique.boxLineReduction;
        continue;
      }
      if (_applyHiddenPair(candidates)) {
        if (candidates[targetRow][targetCol].length == 1) return SolvingTechnique.hiddenPair;
        continue;
      }
      if (_applyNakedTriple(candidates)) {
        if (candidates[targetRow][targetCol].length == 1) return SolvingTechnique.nakedTriple;
        continue;
      }
      if (_applyXWing(candidates)) {
        if (candidates[targetRow][targetCol].length == 1) return SolvingTechnique.xWing;
        continue;
      }

      break; // 더 이상 진행 불가
    }
    return null;
  }

  /// Hidden Single이 대상 셀에 해당하는지 확인
  static SolvingTechnique? _findHiddenSingleForCell(
    List<List<int>> board, List<List<Set<int>>> candidates,
    int targetRow, int targetCol,
  ) {
    // 행 검사
    for (var n = 1; n <= 9; n++) {
      if (!candidates[targetRow][targetCol].contains(n)) continue;
      var count = 0;
      for (var c = 0; c < 9; c++) {
        if (candidates[targetRow][c].contains(n)) count++;
      }
      if (count == 1) return SolvingTechnique.hiddenSingle;
    }
    // 열 검사
    for (var n = 1; n <= 9; n++) {
      if (!candidates[targetRow][targetCol].contains(n)) continue;
      var count = 0;
      for (var r = 0; r < 9; r++) {
        if (candidates[r][targetCol].contains(n)) count++;
      }
      if (count == 1) return SolvingTechnique.hiddenSingle;
    }
    // 박스 검사
    final boxRow = (targetRow ~/ 3) * 3;
    final boxCol = (targetCol ~/ 3) * 3;
    for (var n = 1; n <= 9; n++) {
      if (!candidates[targetRow][targetCol].contains(n)) continue;
      var count = 0;
      for (var r = boxRow; r < boxRow + 3; r++) {
        for (var c = boxCol; c < boxCol + 3; c++) {
          if (candidates[r][c].contains(n)) count++;
        }
      }
      if (count == 1) return SolvingTechnique.hiddenSingle;
    }
    return null;
  }

  // === 내부 구현 ===

  /// 후보 숫자 초기화
  static List<List<Set<int>>> _initCandidates(List<List<int>> board) {
    final candidates = List.generate(
      9,
      (_) => List.generate(9, (_) => <int>{}),
    );
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          candidates[r][c] = _getCandidatesForCell(board, r, c);
        }
      }
    }
    return candidates;
  }

  /// 특정 셀의 후보 숫자
  static Set<int> _getCandidatesForCell(List<List<int>> board, int row, int col) {
    final used = <int>{};
    for (var i = 0; i < 9; i++) {
      if (board[row][i] > 0) used.add(board[row][i]);
      if (board[i][col] > 0) used.add(board[i][col]);
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] > 0) used.add(board[r][c]);
      }
    }
    return {for (var n = 1; n <= 9; n++) if (!used.contains(n)) n};
  }

  /// Naked Single: 후보가 1개인 셀에 값 확정
  static bool _applyNakedSingle(List<List<int>> board, List<List<Set<int>>> candidates) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0 && candidates[r][c].length == 1) {
          final value = candidates[r][c].first;
          _placeValue(board, candidates, r, c, value);
          return true;
        }
      }
    }
    return false;
  }

  /// Hidden Single: 영역(행/열/박스) 내에서 특정 숫자가 한 셀에서만 가능
  static bool _applyHiddenSingle(List<List<int>> board, List<List<Set<int>>> candidates) {
    // 행 검사
    for (var r = 0; r < 9; r++) {
      for (var n = 1; n <= 9; n++) {
        final positions = <int>[];
        for (var c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) positions.add(c);
        }
        if (positions.length == 1) {
          _placeValue(board, candidates, r, positions[0], n);
          return true;
        }
      }
    }
    // 열 검사
    for (var c = 0; c < 9; c++) {
      for (var n = 1; n <= 9; n++) {
        final positions = <int>[];
        for (var r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) positions.add(r);
        }
        if (positions.length == 1) {
          _placeValue(board, candidates, positions[0], c, n);
          return true;
        }
      }
    }
    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        for (var n = 1; n <= 9; n++) {
          final positions = <(int, int)>[];
          for (var r = br * 3; r < br * 3 + 3; r++) {
            for (var c = bc * 3; c < bc * 3 + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add((r, c));
            }
          }
          if (positions.length == 1) {
            final (pr, pc) = positions[0];
            _placeValue(board, candidates, pr, pc, n);
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Naked Pair: 같은 영역의 두 셀이 동일한 2개 후보를 가지면 다른 셀에서 제거
  static bool _applyNakedPair(List<List<Set<int>>> candidates) {
    var changed = false;

    // 행 검사
    for (var r = 0; r < 9; r++) {
      final cells = <int>[];
      for (var c = 0; c < 9; c++) {
        if (candidates[r][c].length == 2) cells.add(c);
      }
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          if (_setsEqual(candidates[r][cells[i]], candidates[r][cells[j]])) {
            final pair = candidates[r][cells[i]];
            for (var c = 0; c < 9; c++) {
              if (c != cells[i] && c != cells[j]) {
                final before = candidates[r][c].length;
                candidates[r][c].removeAll(pair);
                if (candidates[r][c].length < before) changed = true;
              }
            }
          }
        }
      }
    }

    // 열 검사
    for (var c = 0; c < 9; c++) {
      final cells = <int>[];
      for (var r = 0; r < 9; r++) {
        if (candidates[r][c].length == 2) cells.add(r);
      }
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          if (_setsEqual(candidates[cells[i]][c], candidates[cells[j]][c])) {
            final pair = candidates[cells[i]][c];
            for (var r = 0; r < 9; r++) {
              if (r != cells[i] && r != cells[j]) {
                final before = candidates[r][c].length;
                candidates[r][c].removeAll(pair);
                if (candidates[r][c].length < before) changed = true;
              }
            }
          }
        }
      }
    }

    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final cells = <(int, int)>[];
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            if (candidates[r][c].length == 2) cells.add((r, c));
          }
        }
        for (var i = 0; i < cells.length; i++) {
          for (var j = i + 1; j < cells.length; j++) {
            final (r1, c1) = cells[i];
            final (r2, c2) = cells[j];
            if (_setsEqual(candidates[r1][c1], candidates[r2][c2])) {
              final pair = candidates[r1][c1];
              for (var r = br * 3; r < br * 3 + 3; r++) {
                for (var c = bc * 3; c < bc * 3 + 3; c++) {
                  if ((r != r1 || c != c1) && (r != r2 || c != c2)) {
                    final before = candidates[r][c].length;
                    candidates[r][c].removeAll(pair);
                    if (candidates[r][c].length < before) changed = true;
                  }
                }
              }
            }
          }
        }
      }
    }

    return changed;
  }

  /// Pointing Pair: 박스 내에서 특정 숫자의 후보가 한 행/열에만 있으면 해당 행/열의 박스 외부에서 제거
  static bool _applyPointingPair(List<List<Set<int>>> candidates) {
    var changed = false;

    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        for (var n = 1; n <= 9; n++) {
          final positions = <(int, int)>[];
          for (var r = br * 3; r < br * 3 + 3; r++) {
            for (var c = bc * 3; c < bc * 3 + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add((r, c));
            }
          }
          if (positions.length < 2 || positions.length > 3) continue;

          // 같은 행인지 확인
          final rows = positions.map((p) => p.$1).toSet();
          if (rows.length == 1) {
            final row = rows.first;
            for (var c = 0; c < 9; c++) {
              if (c ~/ 3 != bc && candidates[row][c].remove(n)) {
                changed = true;
              }
            }
          }

          // 같은 열인지 확인
          final cols = positions.map((p) => p.$2).toSet();
          if (cols.length == 1) {
            final col = cols.first;
            for (var r = 0; r < 9; r++) {
              if (r ~/ 3 != br && candidates[r][col].remove(n)) {
                changed = true;
              }
            }
          }
        }
      }
    }

    return changed;
  }

  /// Box/Line Reduction: 행/열에서 특정 숫자의 후보가 한 박스에만 있으면 해당 박스의 나머지에서 제거
  static bool _applyBoxLineReduction(List<List<Set<int>>> candidates) {
    var changed = false;

    // 행 검사
    for (var r = 0; r < 9; r++) {
      for (var n = 1; n <= 9; n++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length < 2 || cols.length > 3) continue;
        final boxes = cols.map((c) => c ~/ 3).toSet();
        if (boxes.length == 1) {
          final bc = boxes.first;
          final br = r ~/ 3;
          for (var row = br * 3; row < br * 3 + 3; row++) {
            if (row == r) continue;
            for (var col = bc * 3; col < bc * 3 + 3; col++) {
              if (candidates[row][col].remove(n)) changed = true;
            }
          }
        }
      }
    }

    // 열 검사
    for (var c = 0; c < 9; c++) {
      for (var n = 1; n <= 9; n++) {
        final rows = <int>[];
        for (var r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rows.add(r);
        }
        if (rows.length < 2 || rows.length > 3) continue;
        final boxes = rows.map((r) => r ~/ 3).toSet();
        if (boxes.length == 1) {
          final br = boxes.first;
          final bc = c ~/ 3;
          for (var col = bc * 3; col < bc * 3 + 3; col++) {
            if (col == c) continue;
            for (var row = br * 3; row < br * 3 + 3; row++) {
              if (candidates[row][col].remove(n)) changed = true;
            }
          }
        }
      }
    }

    return changed;
  }

  /// Hidden Pair: 영역 내에서 두 숫자가 같은 두 셀에서만 후보인 경우 그 셀의 다른 후보 제거
  static bool _applyHiddenPair(List<List<Set<int>>> candidates) {
    var changed = false;

    // 행 검사
    for (var r = 0; r < 9; r++) {
      if (_applyHiddenPairInGroup(
        [for (var c = 0; c < 9; c++) candidates[r][c]],
      )) {
        changed = true;
      }
    }

    // 열 검사
    for (var c = 0; c < 9; c++) {
      if (_applyHiddenPairInGroup(
        [for (var r = 0; r < 9; r++) candidates[r][c]],
      )) {
        changed = true;
      }
    }

    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final group = <Set<int>>[];
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            group.add(candidates[r][c]);
          }
        }
        if (_applyHiddenPairInGroup(group)) changed = true;
      }
    }

    return changed;
  }

  static bool _applyHiddenPairInGroup(List<Set<int>> group) {
    var changed = false;
    for (var n1 = 1; n1 <= 8; n1++) {
      for (var n2 = n1 + 1; n2 <= 9; n2++) {
        // n1이 존재하는 위치와 n2가 존재하는 위치를 각각 탐색
        final posN1 = <int>[];
        final posN2 = <int>[];
        for (var i = 0; i < 9; i++) {
          if (group[i].contains(n1)) posN1.add(i);
          if (group[i].contains(n2)) posN2.add(i);
        }
        // 두 숫자 모두 정확히 같은 2개 셀에만 존재해야 함
        if (posN1.length != 2 || posN2.length != 2) continue;
        if (posN1[0] != posN2[0] || posN1[1] != posN2[1]) continue;

        // hidden pair 확인 — 두 셀에서 n1, n2 외의 후보 제거
        for (final pos in posN1) {
          if (group[pos].length > 2) {
            final before = group[pos].length;
            group[pos].retainAll({n1, n2});
            if (group[pos].length < before) changed = true;
          }
        }
      }
    }
    return changed;
  }

  /// Naked Triple: 세 셀의 후보 합집합이 3개인 경우 다른 셀에서 제거
  static bool _applyNakedTriple(List<List<Set<int>>> candidates) {
    var changed = false;

    // 행 검사
    for (var r = 0; r < 9; r++) {
      final cells = <int>[];
      for (var c = 0; c < 9; c++) {
        final len = candidates[r][c].length;
        // 후보 1~3개인 셀 모두 포함 (1개짜리도 트리플의 부분집합 가능)
        if (len >= 1 && len <= 3) cells.add(c);
      }
      if (cells.length < 3) continue;
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          for (var k = j + 1; k < cells.length; k++) {
            final union = {
              ...candidates[r][cells[i]],
              ...candidates[r][cells[j]],
              ...candidates[r][cells[k]],
            };
            if (union.length == 3) {
              for (var c = 0; c < 9; c++) {
                if (c != cells[i] && c != cells[j] && c != cells[k]) {
                  final before = candidates[r][c].length;
                  candidates[r][c].removeAll(union);
                  if (candidates[r][c].length < before) changed = true;
                }
              }
            }
          }
        }
      }
    }

    // 열 검사
    for (var c = 0; c < 9; c++) {
      final cells = <int>[];
      for (var r = 0; r < 9; r++) {
        final len = candidates[r][c].length;
        if (len >= 1 && len <= 3) cells.add(r);
      }
      if (cells.length < 3) continue;
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          for (var k = j + 1; k < cells.length; k++) {
            final union = {
              ...candidates[cells[i]][c],
              ...candidates[cells[j]][c],
              ...candidates[cells[k]][c],
            };
            if (union.length == 3) {
              for (var r = 0; r < 9; r++) {
                if (r != cells[i] && r != cells[j] && r != cells[k]) {
                  final before = candidates[r][c].length;
                  candidates[r][c].removeAll(union);
                  if (candidates[r][c].length < before) changed = true;
                }
              }
            }
          }
        }
      }
    }

    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final cells = <(int, int)>[];
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            final len = candidates[r][c].length;
            if (len >= 1 && len <= 3) cells.add((r, c));
          }
        }
        if (cells.length < 3) continue;
        for (var i = 0; i < cells.length; i++) {
          for (var j = i + 1; j < cells.length; j++) {
            for (var k = j + 1; k < cells.length; k++) {
              final (r1, c1) = cells[i];
              final (r2, c2) = cells[j];
              final (r3, c3) = cells[k];
              final union = {
                ...candidates[r1][c1],
                ...candidates[r2][c2],
                ...candidates[r3][c3],
              };
              if (union.length == 3) {
                for (var r = br * 3; r < br * 3 + 3; r++) {
                  for (var c = bc * 3; c < bc * 3 + 3; c++) {
                    if ((r != r1 || c != c1) &&
                        (r != r2 || c != c2) &&
                        (r != r3 || c != c3)) {
                      final before = candidates[r][c].length;
                      candidates[r][c].removeAll(union);
                      if (candidates[r][c].length < before) changed = true;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return changed;
  }

  /// 값을 배치하고 관련 후보를 업데이트
  static void _placeValue(
    List<List<int>> board,
    List<List<Set<int>>> candidates,
    int row,
    int col,
    int value,
  ) {
    board[row][col] = value;
    candidates[row][col] = {};
    // 관련 영역에서 후보 제거
    for (var i = 0; i < 9; i++) {
      candidates[row][i].remove(value);
      candidates[i][col].remove(value);
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        candidates[r][c].remove(value);
      }
    }
  }

  /// Hidden Single 검색 (힌트 결과 반환용)
  static TechniqueResult? _findHiddenSingle(
    List<List<int>> board,
    List<List<Set<int>>> candidates,
  ) {
    // 행 검사
    for (var r = 0; r < 9; r++) {
      for (var n = 1; n <= 9; n++) {
        final positions = <int>[];
        for (var c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) positions.add(c);
        }
        if (positions.length == 1) {
          return TechniqueResult(
            technique: SolvingTechnique.hiddenSingle,
            row: r,
            col: positions[0],
            value: n,
            explanation: '행 ${r + 1}에서 $n이 들어갈 수 있는 위치가 여기뿐입니다.',
          );
        }
      }
    }
    // 열 검사
    for (var c = 0; c < 9; c++) {
      for (var n = 1; n <= 9; n++) {
        final positions = <int>[];
        for (var r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) positions.add(r);
        }
        if (positions.length == 1) {
          return TechniqueResult(
            technique: SolvingTechnique.hiddenSingle,
            row: positions[0],
            col: c,
            value: n,
            explanation: '열 ${c + 1}에서 $n이 들어갈 수 있는 위치가 여기뿐입니다.',
          );
        }
      }
    }
    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        for (var n = 1; n <= 9; n++) {
          final positions = <(int, int)>[];
          for (var r = br * 3; r < br * 3 + 3; r++) {
            for (var c = bc * 3; c < bc * 3 + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add((r, c));
            }
          }
          if (positions.length == 1) {
            final (pr, pc) = positions[0];
            return TechniqueResult(
              technique: SolvingTechnique.hiddenSingle,
              row: pr,
              col: pc,
              value: n,
              explanation: '이 3×3 박스에서 $n이 들어갈 수 있는 위치가 여기뿐입니다.',
            );
          }
        }
      }
    }
    return null;
  }

  /// Naked Pair 검색 (힌트 결과 반환용) — 행/열/박스 전체 검색
  static TechniqueResult? _findNakedPair(List<List<Set<int>>> candidates) {
    // 행 검사
    for (var r = 0; r < 9; r++) {
      final pairCells = <int>[];
      for (var c = 0; c < 9; c++) {
        if (candidates[r][c].length == 2) pairCells.add(c);
      }
      for (var i = 0; i < pairCells.length; i++) {
        for (var j = i + 1; j < pairCells.length; j++) {
          if (_setsEqual(candidates[r][pairCells[i]], candidates[r][pairCells[j]])) {
            final pair = candidates[r][pairCells[i]];
            // 제거 효과 확인
            var hasEffect = false;
            for (var c = 0; c < 9; c++) {
              if (c != pairCells[i] && c != pairCells[j]) {
                if (candidates[r][c].any((n) => pair.contains(n))) {
                  hasEffect = true;
                  break;
                }
              }
            }
            if (hasEffect) {
              return TechniqueResult(
                technique: SolvingTechnique.nakedPair,
                row: r,
                col: pairCells[i],
                eliminations: pair,
                explanation:
                    '행 ${r + 1}의 열 ${pairCells[i] + 1}과 열 ${pairCells[j] + 1}에 '
                    '${pair.toList()..sort()}만 가능하므로, 이 행의 다른 셀에서 해당 숫자를 제거할 수 있습니다.',
              );
            }
          }
        }
      }
    }

    // 열 검사
    for (var c = 0; c < 9; c++) {
      final pairCells = <int>[];
      for (var r = 0; r < 9; r++) {
        if (candidates[r][c].length == 2) pairCells.add(r);
      }
      for (var i = 0; i < pairCells.length; i++) {
        for (var j = i + 1; j < pairCells.length; j++) {
          if (_setsEqual(candidates[pairCells[i]][c], candidates[pairCells[j]][c])) {
            final pair = candidates[pairCells[i]][c];
            var hasEffect = false;
            for (var r = 0; r < 9; r++) {
              if (r != pairCells[i] && r != pairCells[j]) {
                if (candidates[r][c].any((n) => pair.contains(n))) {
                  hasEffect = true;
                  break;
                }
              }
            }
            if (hasEffect) {
              return TechniqueResult(
                technique: SolvingTechnique.nakedPair,
                row: pairCells[i],
                col: c,
                eliminations: pair,
                explanation:
                    '열 ${c + 1}의 행 ${pairCells[i] + 1}과 행 ${pairCells[j] + 1}에 '
                    '${pair.toList()..sort()}만 가능하므로, 이 열의 다른 셀에서 해당 숫자를 제거할 수 있습니다.',
              );
            }
          }
        }
      }
    }

    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final pairCells = <(int, int)>[];
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            if (candidates[r][c].length == 2) pairCells.add((r, c));
          }
        }
        for (var i = 0; i < pairCells.length; i++) {
          for (var j = i + 1; j < pairCells.length; j++) {
            final (r1, c1) = pairCells[i];
            final (r2, c2) = pairCells[j];
            if (_setsEqual(candidates[r1][c1], candidates[r2][c2])) {
              final pair = candidates[r1][c1];
              var hasEffect = false;
              for (var r = br * 3; r < br * 3 + 3; r++) {
                for (var c = bc * 3; c < bc * 3 + 3; c++) {
                  if ((r != r1 || c != c1) && (r != r2 || c != c2)) {
                    if (candidates[r][c].any((n) => pair.contains(n))) {
                      hasEffect = true;
                      break;
                    }
                  }
                }
                if (hasEffect) break;
              }
              if (hasEffect) {
                return TechniqueResult(
                  technique: SolvingTechnique.nakedPair,
                  row: r1,
                  col: c1,
                  eliminations: pair,
                  explanation:
                      '이 3×3 박스의 (${r1 + 1},${c1 + 1})과 (${r2 + 1},${c2 + 1})에 '
                      '${pair.toList()..sort()}만 가능하므로, 이 박스의 다른 셀에서 해당 숫자를 제거할 수 있습니다.',
                );
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Pointing Pair 검색 (힌트용)
  static TechniqueResult? _findPointingPair(List<List<Set<int>>> candidates) {
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        for (var n = 1; n <= 9; n++) {
          final positions = <(int, int)>[];
          for (var r = br * 3; r < br * 3 + 3; r++) {
            for (var c = bc * 3; c < bc * 3 + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add((r, c));
            }
          }
          if (positions.length < 2 || positions.length > 3) continue;

          final rows = positions.map((p) => p.$1).toSet();
          if (rows.length == 1) {
            final row = rows.first;
            // 박스 외부 같은 행에 n이 있는지 확인
            var hasExternal = false;
            for (var c = 0; c < 9; c++) {
              if (c ~/ 3 != bc && candidates[row][c].contains(n)) {
                hasExternal = true;
                break;
              }
            }
            if (hasExternal) {
              return TechniqueResult(
                technique: SolvingTechnique.pointingPair,
                row: positions[0].$1,
                col: positions[0].$2,
                eliminations: {n},
                explanation: '3×3 박스 내에서 $n은 행 ${row + 1}에만 가능하므로, '
                    '이 행의 박스 바깥 셀에서 $n을 제거할 수 있습니다.',
              );
            }
          }

          final cols = positions.map((p) => p.$2).toSet();
          if (cols.length == 1) {
            final col = cols.first;
            var hasExternal = false;
            for (var r = 0; r < 9; r++) {
              if (r ~/ 3 != br && candidates[r][col].contains(n)) {
                hasExternal = true;
                break;
              }
            }
            if (hasExternal) {
              return TechniqueResult(
                technique: SolvingTechnique.pointingPair,
                row: positions[0].$1,
                col: positions[0].$2,
                eliminations: {n},
                explanation: '3×3 박스 내에서 $n은 열 ${col + 1}에만 가능하므로, '
                    '이 열의 박스 바깥 셀에서 $n을 제거할 수 있습니다.',
              );
            }
          }
        }
      }
    }
    return null;
  }

  /// Box/Line Reduction 검색 (힌트용)
  static TechniqueResult? _findBoxLineReduction(List<List<Set<int>>> candidates) {
    // 행 기반
    for (var r = 0; r < 9; r++) {
      for (var n = 1; n <= 9; n++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length < 2 || cols.length > 3) continue;
        final boxes = cols.map((c) => c ~/ 3).toSet();
        if (boxes.length == 1) {
          final bc = boxes.first;
          final br = r ~/ 3;
          // 박스 내 같은 행 외의 셀에 n이 있는지 확인
          var hasOther = false;
          for (var row = br * 3; row < br * 3 + 3; row++) {
            if (row == r) continue;
            for (var col = bc * 3; col < bc * 3 + 3; col++) {
              if (candidates[row][col].contains(n)) {
                hasOther = true;
                break;
              }
            }
            if (hasOther) break;
          }
          if (hasOther) {
            return TechniqueResult(
              technique: SolvingTechnique.boxLineReduction,
              row: r,
              col: cols[0],
              eliminations: {n},
              explanation: '행 ${r + 1}에서 $n은 하나의 3×3 박스에만 가능하므로, '
                  '해당 박스의 다른 행에서 $n을 제거할 수 있습니다.',
            );
          }
        }
      }
    }

    // 열 기반
    for (var c = 0; c < 9; c++) {
      for (var n = 1; n <= 9; n++) {
        final rows = <int>[];
        for (var r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rows.add(r);
        }
        if (rows.length < 2 || rows.length > 3) continue;
        final boxes = rows.map((r) => r ~/ 3).toSet();
        if (boxes.length == 1) {
          final br = boxes.first;
          final bc = c ~/ 3;
          var hasOther = false;
          for (var col = bc * 3; col < bc * 3 + 3; col++) {
            if (col == c) continue;
            for (var row = br * 3; row < br * 3 + 3; row++) {
              if (candidates[row][col].contains(n)) {
                hasOther = true;
                break;
              }
            }
            if (hasOther) break;
          }
          if (hasOther) {
            return TechniqueResult(
              technique: SolvingTechnique.boxLineReduction,
              row: rows[0],
              col: c,
              eliminations: {n},
              explanation: '열 ${c + 1}에서 $n은 하나의 3×3 박스에만 가능하므로, '
                  '해당 박스의 다른 열에서 $n을 제거할 수 있습니다.',
            );
          }
        }
      }
    }
    return null;
  }

  /// Hidden Pair 검색 (힌트용)
  /// eliminations: 제거 대상 후보 (유지할 {n1,n2}가 아닌, 셀에서 제거될 후보들)
  static TechniqueResult? _findHiddenPair(List<List<Set<int>>> candidates) {
    // 행 검사
    for (var r = 0; r < 9; r++) {
      final group = [for (var c = 0; c < 9; c++) candidates[r][c]];
      final result = _findHiddenPairInGroup(group);
      if (result != null) {
        final (pos, n1, n2) = result;
        final removed = Set<int>.from(group[pos])..removeAll({n1, n2});
        return TechniqueResult(
          technique: SolvingTechnique.hiddenPair,
          row: r,
          col: pos,
          eliminations: removed,
          explanation: '행 ${r + 1}에서 $n1과 $n2는 두 셀에만 존재하므로, '
              '해당 셀의 다른 후보 ${removed.toList()..sort()}를 제거할 수 있습니다.',
        );
      }
    }

    // 열 검사
    for (var c = 0; c < 9; c++) {
      final group = [for (var r = 0; r < 9; r++) candidates[r][c]];
      final result = _findHiddenPairInGroup(group);
      if (result != null) {
        final (pos, n1, n2) = result;
        final removed = Set<int>.from(group[pos])..removeAll({n1, n2});
        return TechniqueResult(
          technique: SolvingTechnique.hiddenPair,
          row: pos,
          col: c,
          eliminations: removed,
          explanation: '열 ${c + 1}에서 $n1과 $n2는 두 셀에만 존재하므로, '
              '해당 셀의 다른 후보 ${removed.toList()..sort()}를 제거할 수 있습니다.',
        );
      }
    }

    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final group = <Set<int>>[];
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            group.add(candidates[r][c]);
          }
        }
        final result = _findHiddenPairInGroup(group);
        if (result != null) {
          final (pos, n1, n2) = result;
          final targetR = br * 3 + pos ~/ 3;
          final targetC = bc * 3 + pos % 3;
          final removed = Set<int>.from(group[pos])..removeAll({n1, n2});
          return TechniqueResult(
            technique: SolvingTechnique.hiddenPair,
            row: targetR,
            col: targetC,
            eliminations: removed,
            explanation: '이 3×3 박스에서 $n1과 $n2는 두 셀에만 존재하므로, '
                '해당 셀의 다른 후보 ${removed.toList()..sort()}를 제거할 수 있습니다.',
          );
        }
      }
    }
    return null;
  }

  /// Hidden Pair 그룹 내 검색 — (위치, n1, n2) 반환, 제거 효과가 있는 경우만
  static (int, int, int)? _findHiddenPairInGroup(List<Set<int>> group) {
    for (var n1 = 1; n1 <= 8; n1++) {
      for (var n2 = n1 + 1; n2 <= 9; n2++) {
        final posN1 = <int>[];
        final posN2 = <int>[];
        for (var i = 0; i < 9; i++) {
          if (group[i].contains(n1)) posN1.add(i);
          if (group[i].contains(n2)) posN2.add(i);
        }
        if (posN1.length != 2 || posN2.length != 2) continue;
        if (posN1[0] != posN2[0] || posN1[1] != posN2[1]) continue;
        // 제거 효과가 있는지 확인 (두 셀에 n1,n2 외 다른 후보가 있어야 힌트 가치 있음)
        if (group[posN1[0]].length > 2 || group[posN1[1]].length > 2) {
          return (posN1[0], n1, n2);
        }
      }
    }
    return null;
  }

  /// Naked Triple 검색 (힌트용) — 행/열/박스 전체 검색
  static TechniqueResult? _findNakedTriple(List<List<Set<int>>> candidates) {
    // 행 검사
    for (var r = 0; r < 9; r++) {
      final cells = <int>[];
      for (var c = 0; c < 9; c++) {
        final len = candidates[r][c].length;
        if (len >= 1 && len <= 3) cells.add(c);
      }
      if (cells.length < 3) continue;
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          for (var k = j + 1; k < cells.length; k++) {
            final union = {
              ...candidates[r][cells[i]],
              ...candidates[r][cells[j]],
              ...candidates[r][cells[k]],
            };
            if (union.length == 3) {
              var hasEffect = false;
              for (var c = 0; c < 9; c++) {
                if (c != cells[i] && c != cells[j] && c != cells[k]) {
                  if (candidates[r][c].any((n) => union.contains(n))) {
                    hasEffect = true;
                    break;
                  }
                }
              }
              if (hasEffect) {
                return TechniqueResult(
                  technique: SolvingTechnique.nakedTriple,
                  row: r,
                  col: cells[i],
                  eliminations: union,
                  explanation: '행 ${r + 1}의 열 ${cells[i] + 1}, ${cells[j] + 1}, '
                      '${cells[k] + 1}에 ${union.toList()..sort()}만 가능하므로, '
                      '이 행의 다른 셀에서 해당 숫자를 제거할 수 있습니다.',
                );
              }
            }
          }
        }
      }
    }

    // 열 검사
    for (var c = 0; c < 9; c++) {
      final cells = <int>[];
      for (var r = 0; r < 9; r++) {
        final len = candidates[r][c].length;
        if (len >= 1 && len <= 3) cells.add(r);
      }
      if (cells.length < 3) continue;
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          for (var k = j + 1; k < cells.length; k++) {
            final union = {
              ...candidates[cells[i]][c],
              ...candidates[cells[j]][c],
              ...candidates[cells[k]][c],
            };
            if (union.length == 3) {
              var hasEffect = false;
              for (var r = 0; r < 9; r++) {
                if (r != cells[i] && r != cells[j] && r != cells[k]) {
                  if (candidates[r][c].any((n) => union.contains(n))) {
                    hasEffect = true;
                    break;
                  }
                }
              }
              if (hasEffect) {
                return TechniqueResult(
                  technique: SolvingTechnique.nakedTriple,
                  row: cells[i],
                  col: c,
                  eliminations: union,
                  explanation: '열 ${c + 1}의 행 ${cells[i] + 1}, ${cells[j] + 1}, '
                      '${cells[k] + 1}에 ${union.toList()..sort()}만 가능하므로, '
                      '이 열의 다른 셀에서 해당 숫자를 제거할 수 있습니다.',
                );
              }
            }
          }
        }
      }
    }

    // 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final cells = <(int, int)>[];
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            final len = candidates[r][c].length;
            if (len >= 1 && len <= 3) cells.add((r, c));
          }
        }
        if (cells.length < 3) continue;
        for (var i = 0; i < cells.length; i++) {
          for (var j = i + 1; j < cells.length; j++) {
            for (var k = j + 1; k < cells.length; k++) {
              final (r1, c1) = cells[i];
              final (r2, c2) = cells[j];
              final (r3, c3) = cells[k];
              final union = {
                ...candidates[r1][c1],
                ...candidates[r2][c2],
                ...candidates[r3][c3],
              };
              if (union.length == 3) {
                var hasEffect = false;
                for (var r = br * 3; r < br * 3 + 3; r++) {
                  for (var c = bc * 3; c < bc * 3 + 3; c++) {
                    if ((r != r1 || c != c1) &&
                        (r != r2 || c != c2) &&
                        (r != r3 || c != c3)) {
                      if (candidates[r][c].any((n) => union.contains(n))) {
                        hasEffect = true;
                        break;
                      }
                    }
                  }
                  if (hasEffect) break;
                }
                if (hasEffect) {
                  return TechniqueResult(
                    technique: SolvingTechnique.nakedTriple,
                    row: r1,
                    col: c1,
                    eliminations: union,
                    explanation: '이 3×3 박스의 (${r1 + 1},${c1 + 1}), (${r2 + 1},${c2 + 1}), '
                        '(${r3 + 1},${c3 + 1})에 ${union.toList()..sort()}만 가능하므로, '
                        '이 박스의 다른 셀에서 해당 숫자를 제거할 수 있습니다.',
                  );
                }
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// X-Wing 검색 (힌트용) — 행 기반 + 열 기반
  static TechniqueResult? _findXWing(List<List<Set<int>>> candidates) {
    for (var n = 1; n <= 9; n++) {
      // 행 기반 X-Wing
      final rowPositions = <int, List<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length == 2) rowPositions[r] = cols;
      }

      final rows = rowPositions.keys.toList();
      for (var i = 0; i < rows.length; i++) {
        for (var j = i + 1; j < rows.length; j++) {
          final r1 = rows[i], r2 = rows[j];
          if (rowPositions[r1]![0] == rowPositions[r2]![0] &&
              rowPositions[r1]![1] == rowPositions[r2]![1]) {
            final c1 = rowPositions[r1]![0];
            final c2 = rowPositions[r1]![1];
            var hasEffect = false;
            for (var r = 0; r < 9; r++) {
              if (r != r1 && r != r2) {
                if (candidates[r][c1].contains(n) || candidates[r][c2].contains(n)) {
                  hasEffect = true;
                  break;
                }
              }
            }
            if (hasEffect) {
              return TechniqueResult(
                technique: SolvingTechnique.xWing,
                row: r1,
                col: c1,
                eliminations: {n},
                explanation: '$n이 행 ${r1 + 1}과 행 ${r2 + 1}에서 열 ${c1 + 1}과 '
                    '열 ${c2 + 1}에만 존재합니다. 해당 열의 다른 행에서 $n을 제거할 수 있습니다.',
              );
            }
          }
        }
      }

      // 열 기반 X-Wing
      final colPositions = <int, List<int>>{};
      for (var c = 0; c < 9; c++) {
        final rowsList = <int>[];
        for (var r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rowsList.add(r);
        }
        if (rowsList.length == 2) colPositions[c] = rowsList;
      }

      final cols = colPositions.keys.toList();
      for (var i = 0; i < cols.length; i++) {
        for (var j = i + 1; j < cols.length; j++) {
          final c1 = cols[i], c2 = cols[j];
          if (colPositions[c1]![0] == colPositions[c2]![0] &&
              colPositions[c1]![1] == colPositions[c2]![1]) {
            final r1 = colPositions[c1]![0];
            final r2 = colPositions[c1]![1];
            var hasEffect = false;
            for (var c = 0; c < 9; c++) {
              if (c != c1 && c != c2) {
                if (candidates[r1][c].contains(n) || candidates[r2][c].contains(n)) {
                  hasEffect = true;
                  break;
                }
              }
            }
            if (hasEffect) {
              return TechniqueResult(
                technique: SolvingTechnique.xWing,
                row: r1,
                col: c1,
                eliminations: {n},
                explanation: '$n이 열 ${c1 + 1}과 열 ${c2 + 1}에서 행 ${r1 + 1}과 '
                    '행 ${r2 + 1}에만 존재합니다. 해당 행의 다른 열에서 $n을 제거할 수 있습니다.',
              );
            }
          }
        }
      }
    }
    return null;
  }

  /// X-Wing: 특정 숫자가 두 행에서 정확히 같은 두 열에만 존재 → 해당 열의 다른 행에서 제거 (열 기반도 동일)
  static bool _applyXWing(List<List<Set<int>>> candidates) {
    var changed = false;

    for (var n = 1; n <= 9; n++) {
      // 행 기반 X-Wing: 숫자 n이 정확히 2개 열에만 존재하는 행 찾기
      final rowPositions = <int, List<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length == 2) rowPositions[r] = cols;
      }

      // 같은 두 열을 공유하는 행 쌍 검색
      final rows = rowPositions.keys.toList();
      for (var i = 0; i < rows.length; i++) {
        for (var j = i + 1; j < rows.length; j++) {
          final r1 = rows[i], r2 = rows[j];
          if (rowPositions[r1]![0] == rowPositions[r2]![0] &&
              rowPositions[r1]![1] == rowPositions[r2]![1]) {
            final c1 = rowPositions[r1]![0];
            final c2 = rowPositions[r1]![1];
            // 해당 두 열에서 r1, r2 외의 행에서 n 제거
            for (var r = 0; r < 9; r++) {
              if (r != r1 && r != r2) {
                if (candidates[r][c1].remove(n)) changed = true;
                if (candidates[r][c2].remove(n)) changed = true;
              }
            }
          }
        }
      }

      // 열 기반 X-Wing: 숫자 n이 정확히 2개 행에만 존재하는 열 찾기
      final colPositions = <int, List<int>>{};
      for (var c = 0; c < 9; c++) {
        final rowsList = <int>[];
        for (var r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rowsList.add(r);
        }
        if (rowsList.length == 2) colPositions[c] = rowsList;
      }

      final cols = colPositions.keys.toList();
      for (var i = 0; i < cols.length; i++) {
        for (var j = i + 1; j < cols.length; j++) {
          final c1 = cols[i], c2 = cols[j];
          if (colPositions[c1]![0] == colPositions[c2]![0] &&
              colPositions[c1]![1] == colPositions[c2]![1]) {
            final r1 = colPositions[c1]![0];
            final r2 = colPositions[c1]![1];
            // 해당 두 행에서 c1, c2 외의 열에서 n 제거
            for (var c = 0; c < 9; c++) {
              if (c != c1 && c != c2) {
                if (candidates[r1][c].remove(n)) changed = true;
                if (candidates[r2][c].remove(n)) changed = true;
              }
            }
          }
        }
      }
    }

    return changed;
  }

  static bool _setsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  static List<List<int>> _copyBoard(List<List<int>> board) {
    return List.generate(9, (r) => List<int>.from(board[r]));
  }
}
