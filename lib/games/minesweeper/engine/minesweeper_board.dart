/// 지뢰찾기 보드 모델
///
/// 셀 상태:
/// - 닫힌 셀: isMine 여부 + 주변 지뢰 수(adjacentMines) 보유
/// - 열린 셀: revealed = true
/// - 깃발 셀: flagged = true
library;

/// 개별 셀 상태
class MineCell {
  /// 지뢰 여부
  final bool isMine;

  /// 주변 8방향 지뢰 개수 (0~8)
  final int adjacentMines;

  /// 셀이 열렸는지
  final bool revealed;

  /// 깃발이 세워졌는지
  final bool flagged;

  const MineCell({
    this.isMine = false,
    this.adjacentMines = 0,
    this.revealed = false,
    this.flagged = false,
  });

  MineCell copyWith({
    bool? isMine,
    int? adjacentMines,
    bool? revealed,
    bool? flagged,
  }) {
    return MineCell(
      isMine: isMine ?? this.isMine,
      adjacentMines: adjacentMines ?? this.adjacentMines,
      revealed: revealed ?? this.revealed,
      flagged: flagged ?? this.flagged,
    );
  }

  Map<String, dynamic> toJson() => {
    'isMine': isMine,
    'adjacentMines': adjacentMines,
    'revealed': revealed,
    'flagged': flagged,
  };

  factory MineCell.fromJson(Map<String, dynamic> json) => MineCell(
    isMine: json['isMine'] as bool? ?? false,
    adjacentMines: json['adjacentMines'] as int? ?? 0,
    revealed: json['revealed'] as bool? ?? false,
    flagged: json['flagged'] as bool? ?? false,
  );
}

/// 지뢰찾기 보드
class MinesweeperBoard {
  /// 격자 크기 (rows == cols, 정사각형)
  final int size;

  /// 전체 지뢰 수
  final int mineCount;

  /// 2D 셀 배열 (row-major)
  final List<List<MineCell>> _cells;

  MinesweeperBoard({
    required this.size,
    required this.mineCount,
    required List<List<MineCell>> cells,
  }) : _cells = cells;

  /// 빈 보드 생성
  factory MinesweeperBoard.empty(int size, int mineCount) {
    final cells = List.generate(
      size,
      (_) => List.generate(size, (_) => const MineCell()),
    );
    return MinesweeperBoard(size: size, mineCount: mineCount, cells: cells);
  }

  /// 셀 접근
  MineCell getCell(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) {
      throw RangeError('($row, $col) 범위 초과: 0~${size - 1}');
    }
    return _cells[row][col];
  }

  /// 셀 값 변경 → 새 보드 반환 (불변)
  MinesweeperBoard setCell(int row, int col, MineCell cell) {
    final newCells = List.generate(
      size,
      (r) => List.generate(size, (c) {
        if (r == row && c == col) return cell;
        return _cells[r][c];
      }),
    );
    return MinesweeperBoard(size: size, mineCount: mineCount, cells: newCells);
  }

  /// 셀 열기 → 새 보드 반환
  MinesweeperBoard revealCell(int row, int col) {
    final cell = getCell(row, col);
    if (cell.revealed || cell.flagged) return this;
    return setCell(row, col, cell.copyWith(revealed: true));
  }

  /// 깃발 토글 → 새 보드 반환
  MinesweeperBoard toggleFlag(int row, int col) {
    final cell = getCell(row, col);
    if (cell.revealed) return this;
    return setCell(row, col, cell.copyWith(flagged: !cell.flagged));
  }

  /// 열린 셀 수
  int get revealedCount {
    int count = 0;
    for (final row in _cells) {
      for (final cell in row) {
        if (cell.revealed) count++;
      }
    }
    return count;
  }

  /// 깃발 수
  int get flagCount {
    int count = 0;
    for (final row in _cells) {
      for (final cell in row) {
        if (cell.flagged) count++;
      }
    }
    return count;
  }

  /// 안전한 셀 수 (지뢰가 아닌 셀)
  int get safeCount => size * size - mineCount;

  /// 승리 판정: 지뢰가 아닌 모든 셀이 열린 경우
  bool get isWon => revealedCount == safeCount;

  /// 8방향 이웃 좌표
  List<(int, int)> neighbors(int row, int col) {
    final result = <(int, int)>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          result.add((nr, nc));
        }
      }
    }
    return result;
  }

  /// 보드 복사
  MinesweeperBoard copyWith() {
    final newCells = List.generate(
      size,
      (r) => List.generate(size, (c) => _cells[r][c]),
    );
    return MinesweeperBoard(size: size, mineCount: mineCount, cells: newCells);
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
    'size': size,
    'mineCount': mineCount,
    'cells': _cells
        .map((row) => row.map((c) => c.toJson()).toList())
        .toList(),
  };

  /// JSON 역직렬화
  factory MinesweeperBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final mineCount = json['mineCount'] as int;
    final cellsJson = json['cells'] as List;
    final cells = cellsJson
        .map((row) => (row as List)
            .map((c) => MineCell.fromJson(c as Map<String, dynamic>))
            .toList())
        .toList();
    return MinesweeperBoard(size: size, mineCount: mineCount, cells: cells);
  }

  /// 지뢰 위치 목록
  List<(int, int)> get minePositions {
    final result = <(int, int)>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_cells[r][c].isMine) result.add((r, c));
      }
    }
    return result;
  }

  /// 닫힌 셀(열리지 않고 깃발도 없는) 위치 목록
  List<(int, int)> get closedCells {
    final result = <(int, int)>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!_cells[r][c].revealed && !_cells[r][c].flagged) {
          result.add((r, c));
        }
      }
    }
    return result;
  }
}
