/// 음양(Yin-Yang) 보드 모델
/// - 셀 값: -1(빈칸), 0(흑/●), 1(백/○)
/// - 비나이로와 동일한 이진 구조, 규칙만 다름
library;

class YinYangBoard {
  /// 격자 크기 (홀수/짝수 모두 가능: 5, 7, 10, 14, 16 — master는 유일해 보장 강화로 16)
  final int size;

  /// 셀 데이터 (1차원, row * size + col), 값: -1(빈칸), 0(흑), 1(백)
  final List<int> cells;

  /// 초기 고정 셀 인덱스
  final Set<int> fixed;

  YinYangBoard({
    required this.size,
    required List<int> cells,
    required Set<int> fixed,
  })  : assert(cells.length == size * size),
        cells = List<int>.from(cells),
        fixed = Set<int>.from(fixed);

  /// 빈 보드 생성
  factory YinYangBoard.empty(int size) {
    return YinYangBoard(
      size: size,
      cells: List.filled(size * size, -1),
      fixed: {},
    );
  }

  /// 셀 값 조회
  int getValue(int row, int col) {
    _assertInBounds(row, col);
    return cells[row * size + col];
  }

  /// 셀 값 설정 → 새 보드 반환 (불변)
  YinYangBoard setValue(int row, int col, int value) {
    _assertInBounds(row, col);
    assert(value == -1 || value == 0 || value == 1);

    final idx = row * size + col;
    if (fixed.contains(idx)) return this;

    final newCells = List<int>.from(cells);
    newCells[idx] = value;
    return YinYangBoard(size: size, cells: newCells, fixed: fixed);
  }

  /// 모든 셀이 채워졌는지
  bool get isComplete => !cells.contains(-1);

  /// 빈 셀 개수
  int get emptyCellCount => cells.where((c) => c == -1).length;

  /// 채워진 셀 개수
  int get filledCellCount => cells.where((c) => c != -1).length;

  /// 복사
  YinYangBoard copyWith() {
    return YinYangBoard(
      size: size,
      cells: List<int>.from(cells),
      fixed: Set<int>.from(fixed),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
    'size': size,
    'cells': cells,
    'fixed': fixed.toList(),
  };

  /// JSON 역직렬화
  factory YinYangBoard.fromJson(Map<String, dynamic> json) {
    return YinYangBoard(
      size: json['size'] as int,
      cells: (json['cells'] as List).cast<int>(),
      fixed: (json['fixed'] as List).cast<int>().toSet(),
    );
  }

  void _assertInBounds(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) {
      throw RangeError('($row, $col) 범위 초과: 0~${size - 1}');
    }
  }
}
