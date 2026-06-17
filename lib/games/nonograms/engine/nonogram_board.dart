/// 노노그램 보드 모델
/// 셀 값: -1(빈칸), 0(비어있음 확정/X), 1(채움/■)
library;

class NonogramBoard {
  /// 행 수
  final int rows;

  /// 열 수
  final int cols;

  /// 행 힌트 (각 행의 연속 채움 그룹 크기 리스트)
  final List<List<int>> rowHints;

  /// 열 힌트
  final List<List<int>> colHints;

  /// 셀 데이터 (row-major, 값: -1/0/1)
  final List<int> cells;

  NonogramBoard({
    required this.rows,
    required this.cols,
    required this.rowHints,
    required this.colHints,
    required List<int> cells,
  })  : assert(cells.length == rows * cols),
        cells = List<int>.from(cells);

  /// 빈 보드 생성 (힌트만 있는 상태)
  factory NonogramBoard.empty({
    required int rows,
    required int cols,
    required List<List<int>> rowHints,
    required List<List<int>> colHints,
  }) {
    return NonogramBoard(
      rows: rows, cols: cols,
      rowHints: rowHints, colHints: colHints,
      cells: List<int>.filled(rows * cols, -1),
    );
  }

  /// 정사각형 편의 접근
  int get size => rows; // rows == cols일 때

  /// 셀 값 조회
  int getValue(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      throw RangeError('($row, $col) 범위 초과');
    }
    return cells[row * cols + col];
  }

  /// 셀 값 설정 → 새 보드 (불변)
  NonogramBoard setValue(int row, int col, int value) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      throw RangeError('($row, $col) 범위 초과');
    }
    final newCells = List<int>.from(cells);
    newCells[row * cols + col] = value;
    return NonogramBoard(
      rows: rows, cols: cols,
      rowHints: rowHints, colHints: colHints,
      cells: newCells,
    );
  }

  /// 행 데이터 추출
  List<int> getRow(int row) {
    return List.generate(cols, (c) => cells[row * cols + c]);
  }

  /// 열 데이터 추출
  List<int> getCol(int col) {
    return List.generate(rows, (r) => cells[r * cols + col]);
  }

  /// 채워진 셀 수
  int get filledCount => cells.where((c) => c == 1).length;

  /// 빈 셀(미결정) 수
  int get undecidedCount => cells.where((c) => c == -1).length;

  /// 모든 셀이 결정되었는지 (빈칸 없음)
  bool get isComplete => !cells.contains(-1);

  /// 복사
  NonogramBoard copyWith() {
    return NonogramBoard(
      rows: rows, cols: cols,
      rowHints: rowHints, colHints: colHints,
      cells: List<int>.from(cells),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
    'rows': rows,
    'cols': cols,
    'rowHints': rowHints,
    'colHints': colHints,
    'cells': cells,
  };

  /// JSON 역직렬화
  factory NonogramBoard.fromJson(Map<String, dynamic> json) {
    return NonogramBoard(
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      rowHints: (json['rowHints'] as List).map((r) => (r as List).cast<int>()).toList(),
      colHints: (json['colHints'] as List).map((c) => (c as List).cast<int>()).toList(),
      cells: (json['cells'] as List).cast<int>(),
    );
  }
}
