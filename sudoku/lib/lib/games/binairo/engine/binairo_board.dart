/// Binairo 보드 모델
/// - size: 격자 크기 (6, 8, 10, 12, 14 — 짝수만)
/// - cells: 1차원 배열 (row * size + col), 값: -1(빈칸), 0, 1
/// - fixed: 초기에 주어진 셀 위치 Set
class BinairoBoard {
  /// 격자 크기 (짝수: 6, 8, 10, 12, 14)
  final int size;

  /// 셀 데이터 (1차원, row * size + col), 값: -1(빈칸), 0, 1
  final List<int> cells;

  /// 초기에 주어진(고정된) 셀 인덱스 집합
  final Set<int> fixed;

  BinairoBoard({
    required this.size,
    required List<int> cells,
    required Set<int> fixed,
  })  : assert(size % 2 == 0 && size >= 6, '크기는 6 이상 짝수여야 합니다'),
        assert(cells.length == size * size, '셀 배열 길이가 size*size와 다릅니다'),
        cells = List<int>.from(cells),
        fixed = Set<int>.from(fixed);

  /// 특정 셀의 값 조회
  int getValue(int row, int col) {
    _assertInBounds(row, col);
    return cells[row * size + col];
  }

  /// 특정 셀에 값 설정 (불변 — 새 보드 반환)
  BinairoBoard setValue(int row, int col, int value) {
    _assertInBounds(row, col);
    assert(value == -1 || value == 0 || value == 1, '값은 -1, 0, 1만 가능합니다');

    final idx = row * size + col;
    // 고정 셀은 변경 불가
    if (fixed.contains(idx)) return this;

    final newCells = List<int>.from(cells);
    newCells[idx] = value;
    return BinairoBoard(size: size, cells: newCells, fixed: fixed);
  }

  /// 모든 셀이 채워졌는지 (빈칸 없음)
  bool get isComplete {
    return !cells.contains(-1);
  }

  /// 빈 셀 개수
  int get emptyCellCount {
    return cells.where((v) => v == -1).length;
  }

  /// 채워진 셀 개수
  int get filledCellCount {
    return cells.where((v) => v != -1).length;
  }

  /// 총 셀 개수
  int get totalCells => size * size;

  /// 깊은 복사
  BinairoBoard copyWith({
    int? size,
    List<int>? cells,
    Set<int>? fixed,
  }) {
    return BinairoBoard(
      size: size ?? this.size,
      cells: cells ?? List<int>.from(this.cells),
      fixed: fixed ?? Set<int>.from(this.fixed),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'cells': cells.join(','),
      'fixed': fixed.toList(),
    };
  }

  /// JSON 역직렬화
  factory BinairoBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsStr = json['cells'] as String;
    final cells = cellsStr.split(',').map(int.parse).toList();
    final fixedList = (json['fixed'] as List<dynamic>).cast<int>();

    return BinairoBoard(
      size: size,
      cells: cells,
      fixed: Set<int>.from(fixedList),
    );
  }

  /// 빈 보드 생성
  factory BinairoBoard.empty(int size) {
    assert(size % 2 == 0 && size >= 6, '크기는 6 이상 짝수여야 합니다');
    return BinairoBoard(
      size: size,
      cells: List<int>.filled(size * size, -1),
      fixed: {},
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
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final v = getValue(r, c);
        buffer.write(v == -1 ? '.' : '$v');
        if (c < size - 1) buffer.write(' ');
      }
      if (r < size - 1) buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BinairoBoard) return false;
    if (size != other.size) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));
}
