/// 킬러 스도쿠 케이지 정의
class Cage {
  /// 케이지에 포함된 셀 좌표 목록
  final List<(int, int)> cells;

  /// 케이지 내 숫자의 합계
  final int sum;

  const Cage({required this.cells, required this.sum});

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'cells': cells.map((c) => [c.$1, c.$2]).toList(),
        'sum': sum,
      };

  /// JSON 역직렬화
  factory Cage.fromJson(Map<String, dynamic> json) {
    final cellList = (json['cells'] as List<dynamic>)
        .map((c) {
          final pair = c as List<dynamic>;
          return (pair[0] as int, pair[1] as int);
        })
        .toList();
    return Cage(cells: cellList, sum: json['sum'] as int);
  }

  @override
  String toString() => 'Cage(sum=$sum, cells=$cells)';
}

/// 킬러 스도쿠 보드 모델
/// - 9x9 격자, 값: 0(빈칸), 1~9
/// - cages: 케이지 목록 (전체 81셀을 빈틈없이 커버)
/// - solution: 정답 보드
/// - isFixed: 난이도에 따라 미리 제공된 힌트 셀
class KillerSudokuBoard {
  /// 현재 보드 상태 (9x9, 0=빈칸)
  final List<List<int>> cells;

  /// 정답 보드
  final List<List<int>> solution;

  /// 케이지 목록
  final List<Cage> cages;

  /// 고정 셀 마스크 (미리 제공된 힌트)
  final List<List<bool>> isFixed;

  /// 메모 (각 셀의 후보 숫자 집합)
  final List<List<Set<int>>> notes;

  KillerSudokuBoard({
    required List<List<int>> cells,
    required List<List<int>> solution,
    required this.cages,
    List<List<bool>>? isFixed,
    List<List<Set<int>>>? notes,
  })  : cells = _copyBoard(cells),
        solution = _copyBoard(solution),
        isFixed = isFixed ?? _buildEmptyMask(),
        notes = notes ?? _emptyNotes();

  /// 내부 전용 생성자 (깊은 복사 불필요 시)
  KillerSudokuBoard._internal({
    required this.cells,
    required this.solution,
    required this.cages,
    required this.isFixed,
    required this.notes,
  });

  /// 셀 값 조회
  int getValue(int row, int col) => cells[row][col];

  /// 셀에 값 설정 (불변 — 새 보드 반환)
  KillerSudokuBoard setValue(int row, int col, int value) {
    if (isFixed[row][col]) return this;
    final newCells = _copyBoard(cells);
    newCells[row][col] = value;
    final newNotes = _copyNotes(notes);
    // 값을 넣으면 해당 셀 메모 클리어
    if (value != 0) {
      newNotes[row][col] = {};
    }
    return KillerSudokuBoard._internal(
      cells: newCells,
      solution: solution,
      cages: cages,
      isFixed: isFixed,
      notes: newNotes,
    );
  }

  /// 셀 값 삭제
  KillerSudokuBoard clearValue(int row, int col) {
    if (isFixed[row][col]) return this;
    final newCells = _copyBoard(cells);
    newCells[row][col] = 0;
    return KillerSudokuBoard._internal(
      cells: newCells,
      solution: solution,
      cages: cages,
      isFixed: isFixed,
      notes: _copyNotes(notes),
    );
  }

  /// 메모 토글
  KillerSudokuBoard toggleNote(int row, int col, int value) {
    if (isFixed[row][col] || cells[row][col] != 0) return this;
    final newNotes = _copyNotes(notes);
    if (newNotes[row][col].contains(value)) {
      newNotes[row][col].remove(value);
    } else {
      newNotes[row][col].add(value);
    }
    return KillerSudokuBoard._internal(
      cells: _copyBoard(cells),
      solution: solution,
      cages: cages,
      isFixed: isFixed,
      notes: newNotes,
    );
  }

  /// 셀에 값을 넣었을 때 관련 셀의 메모에서 해당 숫자 제거
  KillerSudokuBoard removeRelatedNotes(int row, int col, int value) {
    final newNotes = _copyNotes(notes);
    // 같은 행
    for (var c = 0; c < 9; c++) {
      newNotes[row][c].remove(value);
    }
    // 같은 열
    for (var r = 0; r < 9; r++) {
      newNotes[r][col].remove(value);
    }
    // 같은 3x3 박스
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        newNotes[r][c].remove(value);
      }
    }
    // 같은 케이지
    final cage = getCageAt(row, col);
    if (cage != null) {
      for (final cell in cage.cells) {
        newNotes[cell.$1][cell.$2].remove(value);
      }
    }
    return KillerSudokuBoard._internal(
      cells: _copyBoard(cells),
      solution: solution,
      cages: cages,
      isFixed: isFixed,
      notes: newNotes,
    );
  }

  /// 해당 위치의 케이지 조회
  Cage? getCageAt(int row, int col) {
    for (final cage in cages) {
      for (final cell in cage.cells) {
        if (cell.$1 == row && cell.$2 == col) return cage;
      }
    }
    return null;
  }

  /// 모든 셀이 채워졌는지
  bool get isComplete {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (cells[r][c] == 0) return false;
      }
    }
    return true;
  }

  /// 빈 셀 개수
  int get emptyCellCount {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (cells[r][c] == 0) count++;
      }
    }
    return count;
  }

  /// 채워진 셀 개수 (고정 제외)
  int get userFilledCount {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (cells[r][c] != 0 && !isFixed[r][c]) count++;
      }
    }
    return count;
  }

  /// 고정 셀 개수
  int get fixedCount {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (isFixed[r][c]) count++;
      }
    }
    return count;
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'cells': cells.map((r) => r.join(',')).toList(),
        'solution': solution.map((r) => r.join(',')).toList(),
        'cages': cages.map((c) => c.toJson()).toList(),
        'isFixed': isFixed.map((r) => r.map((v) => v ? 1 : 0).join(',')).toList(),
        'notes': notes
            .map((r) => r.map((s) => s.join(',')).toList())
            .toList(),
      };

  /// JSON 역직렬화
  factory KillerSudokuBoard.fromJson(Map<String, dynamic> json) {
    final cells = (json['cells'] as List<dynamic>)
        .map((r) => (r as String).split(',').map(int.parse).toList())
        .toList();
    final solution = (json['solution'] as List<dynamic>)
        .map((r) => (r as String).split(',').map(int.parse).toList())
        .toList();
    final cages = (json['cages'] as List<dynamic>)
        .map((c) => Cage.fromJson(c as Map<String, dynamic>))
        .toList();
    final isFixed = (json['isFixed'] as List<dynamic>)
        .map((r) => (r as String).split(',').map((v) => v == '1').toList())
        .toList();
    final notesJson = json['notes'] as List<dynamic>?;
    final notes = notesJson != null
        ? notesJson
            .map((r) => (r as List<dynamic>)
                .map((s) {
                  final str = s as String;
                  if (str.isEmpty) return <int>{};
                  return str.split(',').map(int.parse).toSet();
                })
                .toList())
            .toList()
        : _emptyNotes();
    return KillerSudokuBoard._internal(
      cells: cells,
      solution: solution,
      cages: cages,
      isFixed: isFixed,
      notes: notes,
    );
  }

  /// 깊은 복사
  KillerSudokuBoard copyWith({
    List<List<int>>? cells,
    List<List<int>>? solution,
    List<Cage>? cages,
    List<List<bool>>? isFixed,
    List<List<Set<int>>>? notes,
  }) {
    return KillerSudokuBoard._internal(
      cells: cells != null ? _copyBoard(cells) : _copyBoard(this.cells),
      solution: solution ?? this.solution,
      cages: cages ?? this.cages,
      isFixed: isFixed ?? this.isFixed,
      notes: notes != null ? _copyNotes(notes) : _copyNotes(this.notes),
    );
  }

  // === 내부 유틸 ===

  static List<List<int>> _copyBoard(List<List<int>> board) {
    return List.generate(9, (r) => List<int>.from(board[r]));
  }

  static List<List<bool>> _buildEmptyMask() {
    return List.generate(9, (_) => List.filled(9, false));
  }

  static List<List<Set<int>>> _emptyNotes() {
    return List.generate(9, (_) => List.generate(9, (_) => <int>{}));
  }

  static List<List<Set<int>>> _copyNotes(List<List<Set<int>>> notes) {
    return List.generate(
      9,
      (r) => List.generate(9, (c) => Set<int>.from(notes[r][c])),
    );
  }

  @override
  String toString() {
    final buf = StringBuffer();
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        buf.write(cells[r][c] == 0 ? '.' : '${cells[r][c]}');
        if (c < 8) buf.write(' ');
      }
      if (r < 8) buf.writeln();
    }
    return buf.toString();
  }
}
