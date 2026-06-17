/// Skyscrapers 보드 모델
/// - size: 격자 크기 (4~8)
/// - cells: 1차원 배열 (row * size + col), 값: 0(빈칸), 1~N
/// - topClues, bottomClues, leftClues, rightClues: 외곽 힌트 (0=힌트없음)
/// - fixed: 초기에 주어진 셀 위치 Set
/// - notes: 후보 숫자 메모
class SkyscrapersBoard {
  /// 격자 크기 (4~8)
  final int size;

  /// 셀 데이터 (1차원, row * size + col), 값: 0(빈칸), 1~size
  final List<int> cells;

  /// 위쪽 외곽 힌트 (각 열의 위에서 아래로 보이는 빌딩 수)
  final List<int> topClues;

  /// 아래쪽 외곽 힌트 (각 열의 아래에서 위로 보이는 빌딩 수)
  final List<int> bottomClues;

  /// 왼쪽 외곽 힌트 (각 행의 왼쪽에서 오른쪽으로 보이는 빌딩 수)
  final List<int> leftClues;

  /// 오른쪽 외곽 힌트 (각 행의 오른쪽에서 왼쪽으로 보이는 빌딩 수)
  final List<int> rightClues;

  /// 초기에 주어진(고정된) 셀 인덱스 집합
  final Set<int> fixed;

  /// 메모 (후보 숫자) — 셀 인덱스 → 후보 숫자 집합
  final Map<int, Set<int>> notes;

  SkyscrapersBoard({
    required this.size,
    required List<int> cells,
    required List<int> topClues,
    required List<int> bottomClues,
    required List<int> leftClues,
    required List<int> rightClues,
    required Set<int> fixed,
    Map<int, Set<int>>? notes,
  })  : assert(size >= 4 && size <= 8, '크기는 4~8 범위여야 합니다'),
        assert(cells.length == size * size, '셀 배열 길이가 size*size와 다릅니다'),
        assert(topClues.length == size, '위쪽 힌트 길이가 size와 다릅니다'),
        assert(bottomClues.length == size, '아래쪽 힌트 길이가 size와 다릅니다'),
        assert(leftClues.length == size, '왼쪽 힌트 길이가 size와 다릅니다'),
        assert(rightClues.length == size, '오른쪽 힌트 길이가 size와 다릅니다'),
        cells = List<int>.from(cells),
        topClues = List<int>.from(topClues),
        bottomClues = List<int>.from(bottomClues),
        leftClues = List<int>.from(leftClues),
        rightClues = List<int>.from(rightClues),
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
  SkyscrapersBoard setValue(int row, int col, int value) {
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

    return SkyscrapersBoard(
      size: size,
      cells: newCells,
      topClues: topClues,
      bottomClues: bottomClues,
      leftClues: leftClues,
      rightClues: rightClues,
      fixed: fixed,
      notes: newNotes,
    );
  }

  /// 메모 토글 (불변 — 새 보드 반환)
  SkyscrapersBoard toggleNote(int row, int col, int num) {
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

    return SkyscrapersBoard(
      size: size,
      cells: cells,
      topClues: topClues,
      bottomClues: bottomClues,
      leftClues: leftClues,
      rightClues: rightClues,
      fixed: fixed,
      notes: newNotes,
    );
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
  SkyscrapersBoard copyWith({
    int? size,
    List<int>? cells,
    List<int>? topClues,
    List<int>? bottomClues,
    List<int>? leftClues,
    List<int>? rightClues,
    Set<int>? fixed,
    Map<int, Set<int>>? notes,
  }) {
    return SkyscrapersBoard(
      size: size ?? this.size,
      cells: cells ?? List<int>.from(this.cells),
      topClues: topClues ?? List<int>.from(this.topClues),
      bottomClues: bottomClues ?? List<int>.from(this.bottomClues),
      leftClues: leftClues ?? List<int>.from(this.leftClues),
      rightClues: rightClues ?? List<int>.from(this.rightClues),
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
      'topClues': topClues.join(','),
      'bottomClues': bottomClues.join(','),
      'leftClues': leftClues.join(','),
      'rightClues': rightClues.join(','),
      'fixed': fixed.toList(),
      'notes': notesJson,
    };
  }

  /// JSON 역직렬화
  factory SkyscrapersBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsStr = json['cells'] as String;
    final cells = cellsStr.split(',').map(int.parse).toList();
    final topStr = json['topClues'] as String;
    final topClues = topStr.split(',').map(int.parse).toList();
    final bottomStr = json['bottomClues'] as String;
    final bottomClues = bottomStr.split(',').map(int.parse).toList();
    final leftStr = json['leftClues'] as String;
    final leftClues = leftStr.split(',').map(int.parse).toList();
    final rightStr = json['rightClues'] as String;
    final rightClues = rightStr.split(',').map(int.parse).toList();
    final fixedList = (json['fixed'] as List<dynamic>).cast<int>();

    // 메모 역직렬화
    final notesJson = json['notes'] as Map<String, dynamic>? ?? {};
    final notes = <int, Set<int>>{};
    for (final entry in notesJson.entries) {
      final idx = int.parse(entry.key);
      final values = (entry.value as List<dynamic>).cast<int>().toSet();
      notes[idx] = values;
    }

    return SkyscrapersBoard(
      size: size,
      cells: cells,
      topClues: topClues,
      bottomClues: bottomClues,
      leftClues: leftClues,
      rightClues: rightClues,
      fixed: Set<int>.from(fixedList),
      notes: notes,
    );
  }

  /// 빈 보드 생성 (힌트 없음)
  factory SkyscrapersBoard.empty(int size) {
    assert(size >= 4 && size <= 8, '크기는 4~8 범위여야 합니다');
    return SkyscrapersBoard(
      size: size,
      cells: List<int>.filled(size * size, 0),
      topClues: List<int>.filled(size, 0),
      bottomClues: List<int>.filled(size, 0),
      leftClues: List<int>.filled(size, 0),
      rightClues: List<int>.filled(size, 0),
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
    // 위쪽 힌트
    buffer.write('  ');
    for (var c = 0; c < size; c++) {
      buffer.write(topClues[c] == 0 ? '.' : '${topClues[c]}');
      if (c < size - 1) buffer.write(' ');
    }
    buffer.writeln();
    // 격자
    for (var r = 0; r < size; r++) {
      buffer.write(leftClues[r] == 0 ? '.' : '${leftClues[r]}');
      buffer.write(' ');
      for (var c = 0; c < size; c++) {
        final v = getValue(r, c);
        buffer.write(v == 0 ? '.' : '$v');
        if (c < size - 1) buffer.write(' ');
      }
      buffer.write(' ');
      buffer.write(rightClues[r] == 0 ? '.' : '${rightClues[r]}');
      buffer.writeln();
    }
    // 아래쪽 힌트
    buffer.write('  ');
    for (var c = 0; c < size; c++) {
      buffer.write(bottomClues[c] == 0 ? '.' : '${bottomClues[c]}');
      if (c < size - 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SkyscrapersBoard) return false;
    if (size != other.size) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));
}
