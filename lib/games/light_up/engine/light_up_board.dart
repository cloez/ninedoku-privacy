/// Light Up (Akari) 보드 모델
/// - size: 격자 크기 (7, 8, 10, 12, 14)
/// - cells: 1차원 배열 (row * size + col)
///   값: -2(벽, 숫자 없음), -1(빈 흰 칸), 0~4(벽, 인접 전구 수 표시),
///        5(전구 💡), 6(X 표시 — 플레이어 메모)
/// - wallNumbers: 벽 셀의 인접 전구 숫자 (null이면 숫자 없는 벽)
class LightUpBoard {
  /// 격자 크기
  final int size;

  /// 셀 데이터 (1차원, row * size + col)
  /// -2: 벽(숫자 없음), -1: 빈 흰 칸, 0~4: 숫자 벽, 5: 전구, 6: X 메모
  final List<int> cells;

  /// 고정 셀 (벽) 인덱스 집합 — 플레이어가 변경 불가
  final Set<int> fixed;

  // 셀 값 상수
  static const int wallBlank = -2; // 숫자 없는 벽
  static const int empty = -1; // 빈 흰 칸
  // 0, 1, 2, 3, 4 = 숫자 벽
  static const int bulb = 5; // 전구
  static const int cross = 6; // X 메모

  LightUpBoard({
    required this.size,
    required List<int> cells,
    required Set<int> fixed,
  })  : assert(size >= 7, '크기는 7 이상이어야 합니다'),
        assert(cells.length == size * size, '셀 배열 길이가 size*size와 다릅니다'),
        cells = List<int>.from(cells),
        fixed = Set<int>.from(fixed);

  /// 벽인지 확인 (숫자 벽 또는 빈 벽)
  bool isWall(int row, int col) {
    final v = getValue(row, col);
    return v == wallBlank || (v >= 0 && v <= 4);
  }

  /// 벽 숫자 (-1이면 숫자 없음)
  int getWallNumber(int row, int col) {
    final v = getValue(row, col);
    if (v >= 0 && v <= 4) return v;
    return -1;
  }

  /// 흰 칸인지 확인 (빈칸, 전구, X 모두 포함)
  bool isWhite(int row, int col) {
    final v = getValue(row, col);
    return v == empty || v == bulb || v == cross;
  }

  /// 전구인지 확인
  bool isBulb(int row, int col) => getValue(row, col) == bulb;

  /// 특정 셀의 값 조회
  int getValue(int row, int col) {
    _assertInBounds(row, col);
    return cells[row * size + col];
  }

  /// 특정 셀에 값 설정 (불변 — 새 보드 반환)
  LightUpBoard setValue(int row, int col, int value) {
    _assertInBounds(row, col);

    final idx = row * size + col;
    // 고정 셀(벽)은 변경 불가
    if (fixed.contains(idx)) return this;

    final newCells = List<int>.from(cells);
    newCells[idx] = value;
    return LightUpBoard(size: size, cells: newCells, fixed: fixed);
  }

  /// 전구가 비추는 셀 집합 계산
  Set<int> getLitCells() {
    final lit = <int>{};
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (!isBulb(r, c)) continue;
        lit.add(r * size + c); // 전구 자신도 비춤
        // 상하좌우 전파
        for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          var nr = r + dr;
          var nc = c + dc;
          while (nr >= 0 && nr < size && nc >= 0 && nc < size) {
            if (isWall(nr, nc)) break;
            lit.add(nr * size + nc);
            nr += dr;
            nc += dc;
          }
        }
      }
    }
    return lit;
  }

  /// 특정 셀이 빛에 의해 비춰지는지
  bool isLit(int row, int col) {
    if (isBulb(row, col)) return true;
    // 상하좌우에서 전구 찾기
    for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      var nr = row + dr;
      var nc = col + dc;
      while (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        if (isWall(nr, nc)) break;
        if (isBulb(nr, nc)) return true;
        nr += dr;
        nc += dc;
      }
    }
    return false;
  }

  /// 전구 충돌 여부 (같은 행/열에 벽 없이 다른 전구 존재)
  bool hasBulbConflict(int row, int col) {
    if (!isBulb(row, col)) return false;
    for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      var nr = row + dr;
      var nc = col + dc;
      while (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        if (isWall(nr, nc)) break;
        if (isBulb(nr, nc)) return true;
        nr += dr;
        nc += dc;
      }
    }
    return false;
  }

  /// 벽 숫자 인접 전구 수
  int adjacentBulbCount(int row, int col) {
    var count = 0;
    for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      if (isBulb(nr, nc)) count++;
    }
    return count;
  }

  /// 전구 개수
  int get bulbCount {
    return cells.where((v) => v == bulb).length;
  }

  /// 흰 칸 개수 (벽 제외)
  int get whiteCellCount {
    var count = 0;
    for (final v in cells) {
      if (v == empty || v == bulb || v == cross) count++;
    }
    return count;
  }

  /// 총 셀 개수
  int get totalCells => size * size;

  /// 깊은 복사
  LightUpBoard copyWith({
    int? size,
    List<int>? cells,
    Set<int>? fixed,
  }) {
    return LightUpBoard(
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
  factory LightUpBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsStr = json['cells'] as String;
    final cells = cellsStr.split(',').map(int.parse).toList();
    final fixedList = (json['fixed'] as List<dynamic>).cast<int>();

    return LightUpBoard(
      size: size,
      cells: cells,
      fixed: Set<int>.from(fixedList),
    );
  }

  /// 빈 보드 생성 (모두 빈 흰 칸)
  factory LightUpBoard.blank(int size) {
    return LightUpBoard(
      size: size,
      cells: List<int>.filled(size * size, empty),
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
        switch (v) {
          case wallBlank:
            buffer.write('#');
          case empty:
            buffer.write('.');
          case bulb:
            buffer.write('*');
          case cross:
            buffer.write('x');
          default:
            if (v >= 0 && v <= 4) {
              buffer.write('$v');
            } else {
              buffer.write('?');
            }
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
    if (other is! LightUpBoard) return false;
    if (size != other.size) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));
}
