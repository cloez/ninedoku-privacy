/// 후토시키 보드 모델
/// - size: 격자 크기 (4~9)
/// - cells: 1차원 배열 (row * size + col), 값: 0(빈칸), 1~N
/// - horizontalConstraints: 수평 부등호 (N×(N-1)), 값: 0(없음), 1(<), 2(>)
/// - verticalConstraints: 수직 부등호 ((N-1)×N), 값: 0(없음), 1(∧ 위<아래), 2(∨ 위>아래)
/// - fixed: 초기에 주어진 셀 위치 Set
/// - notes: 후보 숫자 메모
class FutoshikiBoard {
  /// 격자 크기 (4~9)
  final int size;

  /// 셀 데이터 (1차원, row * size + col), 값: 0(빈칸), 1~size
  final List<int> cells;

  /// 수평 부등호 제약 (row * (size-1) + col)
  /// 값: 0=없음, 1=왼쪽<오른쪽, 2=왼쪽>오른쪽
  final List<int> horizontalConstraints;

  /// 수직 부등호 제약 (row * size + col)
  /// 값: 0=없음, 1=위<아래, 2=위>아래
  final List<int> verticalConstraints;

  /// 초기에 주어진(고정된) 셀 인덱스 집합
  final Set<int> fixed;

  /// 메모 (후보 숫자) — 셀 인덱스 → 후보 숫자 집합
  final Map<int, Set<int>> notes;

  FutoshikiBoard({
    required this.size,
    required List<int> cells,
    required List<int> horizontalConstraints,
    required List<int> verticalConstraints,
    required Set<int> fixed,
    Map<int, Set<int>>? notes,
  })  : assert(size >= 4 && size <= 9, '크기는 4~9 범위여야 합니다'),
        assert(cells.length == size * size, '셀 배열 길이가 size*size와 다릅니다'),
        assert(horizontalConstraints.length == size * (size - 1),
            '수평 제약 길이가 size*(size-1)과 다릅니다'),
        assert(verticalConstraints.length == (size - 1) * size,
            '수직 제약 길이가 (size-1)*size과 다릅니다'),
        cells = List<int>.from(cells),
        horizontalConstraints = List<int>.from(horizontalConstraints),
        verticalConstraints = List<int>.from(verticalConstraints),
        fixed = Set<int>.from(fixed),
        notes = notes != null
            ? Map<int, Set<int>>.fromEntries(
                notes.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value))))
            : {};

  /// 특정 셀의 값 조회
  int getValue(int row, int col) {
    _assertInBounds(row, col);
    return cells[row * size + col];
  }

  /// 특정 셀에 값 설정 (불변 — 새 보드 반환)
  FutoshikiBoard setValue(int row, int col, int value) {
    _assertInBounds(row, col);
    assert(value >= 0 && value <= size, '값은 0~$size 범위여야 합니다');

    final idx = row * size + col;
    // 고정 셀은 변경 불가
    if (fixed.contains(idx)) return this;

    final newCells = List<int>.from(cells);
    newCells[idx] = value;

    // 값을 넣으면 해당 셀의 메모 제거
    final newNotes = Map<int, Set<int>>.fromEntries(
        notes.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value))));
    if (value != 0) {
      newNotes.remove(idx);
    }

    return FutoshikiBoard(
      size: size,
      cells: newCells,
      horizontalConstraints: horizontalConstraints,
      verticalConstraints: verticalConstraints,
      fixed: fixed,
      notes: newNotes,
    );
  }

  /// 메모 토글 (불변 — 새 보드 반환)
  FutoshikiBoard toggleNote(int row, int col, int num) {
    _assertInBounds(row, col);
    assert(num >= 1 && num <= size, '메모 숫자는 1~$size 범위여야 합니다');

    final idx = row * size + col;
    if (fixed.contains(idx)) return this;
    if (cells[idx] != 0) return this; // 값이 있으면 메모 불가

    final newNotes = Map<int, Set<int>>.fromEntries(
        notes.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value))));
    final cellNotes = newNotes[idx] ?? <int>{};
    if (cellNotes.contains(num)) {
      cellNotes.remove(num);
    } else {
      cellNotes.add(num);
    }
    if (cellNotes.isEmpty) {
      newNotes.remove(idx);
    } else {
      newNotes[idx] = cellNotes;
    }

    return FutoshikiBoard(
      size: size,
      cells: cells,
      horizontalConstraints: horizontalConstraints,
      verticalConstraints: verticalConstraints,
      fixed: fixed,
      notes: newNotes,
    );
  }

  /// 수평 부등호 조회 (row, col) — col과 col+1 사이
  int getHorizontalConstraint(int row, int col) {
    assert(row >= 0 && row < size, '행 범위 초과');
    assert(col >= 0 && col < size - 1, '열 범위 초과 (수평 제약)');
    return horizontalConstraints[row * (size - 1) + col];
  }

  /// 수직 부등호 조회 (row, col) — row와 row+1 사이
  int getVerticalConstraint(int row, int col) {
    assert(row >= 0 && row < size - 1, '행 범위 초과 (수직 제약)');
    assert(col >= 0 && col < size, '열 범위 초과');
    return verticalConstraints[row * size + col];
  }

  /// 모든 셀이 채워졌는지 (빈칸 없음)
  bool get isComplete {
    return !cells.contains(0);
  }

  /// 빈 셀 개수
  int get emptyCellCount {
    return cells.where((v) => v == 0).length;
  }

  /// 채워진 셀 개수
  int get filledCellCount {
    return cells.where((v) => v != 0).length;
  }

  /// 총 셀 개수
  int get totalCells => size * size;

  /// 깊은 복사
  FutoshikiBoard copyWith({
    int? size,
    List<int>? cells,
    List<int>? horizontalConstraints,
    List<int>? verticalConstraints,
    Set<int>? fixed,
    Map<int, Set<int>>? notes,
  }) {
    return FutoshikiBoard(
      size: size ?? this.size,
      cells: cells ?? List<int>.from(this.cells),
      horizontalConstraints:
          horizontalConstraints ?? List<int>.from(this.horizontalConstraints),
      verticalConstraints:
          verticalConstraints ?? List<int>.from(this.verticalConstraints),
      fixed: fixed ?? Set<int>.from(this.fixed),
      notes: notes ??
          Map<int, Set<int>>.fromEntries(
              this.notes.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value)))),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    // 메모를 직렬화: { "인덱스": [숫자, ...] }
    final notesJson = <String, dynamic>{};
    for (final entry in notes.entries) {
      notesJson['${entry.key}'] = entry.value.toList();
    }

    return {
      'size': size,
      'cells': cells.join(','),
      'hConstraints': horizontalConstraints.join(','),
      'vConstraints': verticalConstraints.join(','),
      'fixed': fixed.toList(),
      'notes': notesJson,
    };
  }

  /// JSON 역직렬화
  factory FutoshikiBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsStr = json['cells'] as String;
    final cells = cellsStr.split(',').map(int.parse).toList();
    final hStr = json['hConstraints'] as String;
    final hConstraints = hStr.split(',').map(int.parse).toList();
    final vStr = json['vConstraints'] as String;
    final vConstraints = vStr.split(',').map(int.parse).toList();
    final fixedList = (json['fixed'] as List<dynamic>).cast<int>();

    // 메모 역직렬화
    final notesJson = json['notes'] as Map<String, dynamic>? ?? {};
    final notes = <int, Set<int>>{};
    for (final entry in notesJson.entries) {
      final idx = int.parse(entry.key);
      final values = (entry.value as List<dynamic>).cast<int>().toSet();
      notes[idx] = values;
    }

    return FutoshikiBoard(
      size: size,
      cells: cells,
      horizontalConstraints: hConstraints,
      verticalConstraints: vConstraints,
      fixed: Set<int>.from(fixedList),
      notes: notes,
    );
  }

  /// 빈 보드 생성 (제약 없음)
  factory FutoshikiBoard.empty(int size) {
    assert(size >= 4 && size <= 9, '크기는 4~9 범위여야 합니다');
    return FutoshikiBoard(
      size: size,
      cells: List<int>.filled(size * size, 0),
      horizontalConstraints: List<int>.filled(size * (size - 1), 0),
      verticalConstraints: List<int>.filled((size - 1) * size, 0),
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
      // 셀 행
      for (var c = 0; c < size; c++) {
        final v = getValue(r, c);
        buffer.write(v == 0 ? '.' : '$v');
        // 수평 부등호
        if (c < size - 1) {
          final h = getHorizontalConstraint(r, c);
          buffer.write(h == 1 ? ' < ' : (h == 2 ? ' > ' : '   '));
        }
      }
      buffer.writeln();
      // 수직 부등호 행
      if (r < size - 1) {
        for (var c = 0; c < size; c++) {
          final v = getVerticalConstraint(r, c);
          buffer.write(v == 1 ? '∧' : (v == 2 ? '∨' : ' '));
          if (c < size - 1) buffer.write('   ');
        }
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FutoshikiBoard) return false;
    if (size != other.size) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));
}
