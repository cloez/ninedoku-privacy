/// Tents 보드 모델
/// - size: 격자 크기 (6, 8, 10, 12, master도 12 — 유일해 보장 강화)
/// - cells: 1차원 배열 (row * size + col), 값: 0(빈칸), 1(나무), 2(텐트), 3(잔디)
/// - rowCounts: 각 행에 필요한 텐트 수
/// - colCounts: 각 열에 필요한 텐트 수
class TentsBoard {
  /// 격자 크기
  final int size;

  /// 셀 데이터 (1차원, row * size + col)
  /// 0=빈칸, 1=나무, 2=텐트, 3=잔디
  final List<int> cells;

  /// 각 행에 필요한 텐트 수
  final List<int> rowCounts;

  /// 각 열에 필요한 텐트 수
  final List<int> colCounts;

  /// 나무 위치 인덱스 집합 (고정, 변경 불가)
  final Set<int> treePositions;

  /// 셀 타입 상수
  static const int empty = 0;
  static const int tree = 1;
  static const int tent = 2;
  static const int grass = 3;

  TentsBoard({
    required this.size,
    required List<int> cells,
    required List<int> rowCounts,
    required List<int> colCounts,
    required Set<int> treePositions,
  })  : assert(size >= 6, '크기는 6 이상이어야 합니다'),
        assert(cells.length == size * size, '셀 배열 길이가 size*size와 다릅니다'),
        assert(rowCounts.length == size, 'rowCounts 길이가 size와 다릅니다'),
        assert(colCounts.length == size, 'colCounts 길이가 size와 다릅니다'),
        cells = List<int>.from(cells),
        rowCounts = List<int>.from(rowCounts),
        colCounts = List<int>.from(colCounts),
        treePositions = Set<int>.from(treePositions);

  /// 특정 셀의 값 조회
  int getValue(int row, int col) {
    _assertInBounds(row, col);
    return cells[row * size + col];
  }

  /// 특정 셀에 값 설정 (불변 -- 새 보드 반환)
  TentsBoard setValue(int row, int col, int value) {
    _assertInBounds(row, col);
    assert(value >= 0 && value <= 3, '값은 0~3만 가능합니다');

    final idx = row * size + col;
    // 나무 셀은 변경 불가
    if (treePositions.contains(idx)) return this;

    final newCells = List<int>.from(cells);
    newCells[idx] = value;
    return TentsBoard(
      size: size,
      cells: newCells,
      rowCounts: rowCounts,
      colCounts: colCounts,
      treePositions: treePositions,
    );
  }

  /// 특정 행의 현재 텐트 수
  int currentRowTents(int row) {
    var count = 0;
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == tent) count++;
    }
    return count;
  }

  /// 특정 열의 현재 텐트 수
  int currentColTents(int col) {
    var count = 0;
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == tent) count++;
    }
    return count;
  }

  /// 모든 비나무 셀이 채워졌는지 (빈칸 없음)
  bool get isComplete {
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == empty && !treePositions.contains(i)) return false;
    }
    return true;
  }

  /// 빈 셀 개수 (나무 제외)
  int get emptyCellCount {
    var count = 0;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == empty && !treePositions.contains(i)) count++;
    }
    return count;
  }

  /// 채워진 셀 개수 (텐트 + 잔디)
  int get filledCellCount {
    var count = 0;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == tent || cells[i] == grass) count++;
    }
    return count;
  }

  /// 총 셀 개수
  int get totalCells => size * size;

  /// 비나무 셀 수 (플레이어가 채워야 할 셀)
  int get playableCells => totalCells - treePositions.length;

  /// 깊은 복사
  TentsBoard copyWith({
    int? size,
    List<int>? cells,
    List<int>? rowCounts,
    List<int>? colCounts,
    Set<int>? treePositions,
  }) {
    return TentsBoard(
      size: size ?? this.size,
      cells: cells ?? List<int>.from(this.cells),
      rowCounts: rowCounts ?? List<int>.from(this.rowCounts),
      colCounts: colCounts ?? List<int>.from(this.colCounts),
      treePositions: treePositions ?? Set<int>.from(this.treePositions),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'cells': cells.join(','),
      'rowCounts': rowCounts.join(','),
      'colCounts': colCounts.join(','),
      'treePositions': treePositions.toList(),
    };
  }

  /// JSON 역직렬화
  factory TentsBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cells = (json['cells'] as String).split(',').map(int.parse).toList();
    final rowCounts =
        (json['rowCounts'] as String).split(',').map(int.parse).toList();
    final colCounts =
        (json['colCounts'] as String).split(',').map(int.parse).toList();
    final treeList = (json['treePositions'] as List<dynamic>).cast<int>();

    return TentsBoard(
      size: size,
      cells: cells,
      rowCounts: rowCounts,
      colCounts: colCounts,
      treePositions: Set<int>.from(treeList),
    );
  }

  /// 빈 보드 생성 (나무 없음)
  factory TentsBoard.blank(int size) {
    return TentsBoard(
      size: size,
      cells: List<int>.filled(size * size, 0),
      rowCounts: List<int>.filled(size, 0),
      colCounts: List<int>.filled(size, 0),
      treePositions: {},
    );
  }

  /// 범위 검증
  void _assertInBounds(int row, int col) {
    assert(row >= 0 && row < size, '행 인덱스 범위 초과: $row');
    assert(col >= 0 && col < size, '열 인덱스 범위 초과: $col');
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    // 열 힌트
    buffer.write('  ');
    for (var c = 0; c < size; c++) {
      buffer.write('${colCounts[c]} ');
    }
    buffer.writeln();
    for (var r = 0; r < size; r++) {
      buffer.write('${rowCounts[r]} ');
      for (var c = 0; c < size; c++) {
        final v = getValue(r, c);
        switch (v) {
          case empty:
            buffer.write('.');
          case tree:
            buffer.write('T');
          case tent:
            buffer.write('A');
          case grass:
            buffer.write('x');
        }
        if (c < size - 1) buffer.write(' ');
      }
      if (r < size - 1) buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TentsBoard) return false;
    if (size != other.size) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));
}
