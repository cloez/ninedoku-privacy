/// Star Battle 보드 모델
/// - size: 격자 크기 (6~10)
/// - cells: 1차원 배열 (row * size + col), 값: -1(빈칸), 0(X), 1(★)
/// - regions: 각 셀의 영역 번호 (0 ~ size-1)
/// - starCount: 각 행/열/영역에 배치해야 할 별 수
class StarBattleBoard {
  /// 격자 크기
  final int size;

  /// 셀 데이터 (1차원, row * size + col), 값: -1(빈칸), 0(X), 1(★)
  final List<int> cells;

  /// 각 셀의 영역 번호 (0 ~ size-1)
  final List<int> regions;

  /// 행/열/영역당 별 수 (1-star 또는 2-star)
  final int starCount;

  /// 초기에 주어진(고정된) 셀 인덱스 집합 (Star Battle에서는 빈 보드이므로 보통 비어있음)
  final Set<int> fixed;

  StarBattleBoard({
    required this.size,
    required List<int> cells,
    required List<int> regions,
    required this.starCount,
    Set<int>? fixed,
  })  : assert(size >= 6 && size <= 10, '크기는 6~10 범위여야 합니다'),
        assert(cells.length == size * size, '셀 배열 길이가 size*size와 다릅니다'),
        assert(regions.length == size * size, '영역 배열 길이가 size*size와 다릅니다'),
        assert(starCount >= 1 && starCount <= 2, '별 수는 1~2 범위여야 합니다'),
        cells = List<int>.from(cells),
        regions = List<int>.from(regions),
        fixed = Set<int>.from(fixed ?? {});

  /// 특정 셀의 값 조회
  int getValue(int row, int col) {
    _assertInBounds(row, col);
    return cells[row * size + col];
  }

  /// 특정 셀에 값 설정 (불변 — 새 보드 반환)
  StarBattleBoard setValue(int row, int col, int value) {
    _assertInBounds(row, col);
    assert(value == -1 || value == 0 || value == 1, '값은 -1, 0, 1만 가능합니다');

    final idx = row * size + col;
    if (fixed.contains(idx)) return this;

    final newCells = List<int>.from(cells);
    newCells[idx] = value;
    return StarBattleBoard(
      size: size,
      cells: newCells,
      regions: regions,
      starCount: starCount,
      fixed: fixed,
    );
  }

  /// 특정 셀의 영역 번호 조회
  int getRegion(int row, int col) {
    _assertInBounds(row, col);
    return regions[row * size + col];
  }

  /// 모든 셀이 채워졌는지 (빈칸 없음)
  bool get isComplete {
    return !cells.contains(-1);
  }

  /// 빈 셀 개수
  int get emptyCellCount {
    return cells.where((v) => v == -1).length;
  }

  /// 별이 배치된 셀 개수
  int get starCellCount {
    return cells.where((v) => v == 1).length;
  }

  /// 총 셀 개수
  int get totalCells => size * size;

  /// 필요한 총 별 수
  int get totalStarsNeeded => size * starCount;

  /// 깊은 복사
  StarBattleBoard copyWith({
    int? size,
    List<int>? cells,
    List<int>? regions,
    int? starCount,
    Set<int>? fixed,
  }) {
    return StarBattleBoard(
      size: size ?? this.size,
      cells: cells ?? List<int>.from(this.cells),
      regions: regions ?? List<int>.from(this.regions),
      starCount: starCount ?? this.starCount,
      fixed: fixed ?? Set<int>.from(this.fixed),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'cells': cells.join(','),
      'regions': regions.join(','),
      'starCount': starCount,
      'fixed': fixed.toList(),
    };
  }

  /// JSON 역직렬화
  factory StarBattleBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsStr = json['cells'] as String;
    final cells = cellsStr.split(',').map(int.parse).toList();
    final regionsStr = json['regions'] as String;
    final regions = regionsStr.split(',').map(int.parse).toList();
    final starCount = json['starCount'] as int;
    final fixedList = (json['fixed'] as List<dynamic>?)?.cast<int>() ?? [];

    return StarBattleBoard(
      size: size,
      cells: cells,
      regions: regions,
      starCount: starCount,
      fixed: Set<int>.from(fixedList),
    );
  }

  /// 빈 보드 생성
  factory StarBattleBoard.empty(int size, List<int> regions, int starCount) {
    assert(size >= 6 && size <= 10, '크기는 6~10 범위여야 합니다');
    return StarBattleBoard(
      size: size,
      cells: List<int>.filled(size * size, -1),
      regions: regions,
      starCount: starCount,
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
        buffer.write(v == -1 ? '.' : (v == 0 ? 'X' : '★'));
        if (c < size - 1) buffer.write(' ');
      }
      if (r < size - 1) buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StarBattleBoard) return false;
    if (size != other.size || starCount != other.starCount) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    for (var i = 0; i < regions.length; i++) {
      if (regions[i] != other.regions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, starCount, Object.hashAll(cells), Object.hashAll(regions));
}
