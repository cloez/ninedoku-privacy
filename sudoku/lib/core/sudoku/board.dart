/// 9x9 스도쿠 보드 모델
class SudokuBoard {
  /// 퍼즐 초기 상태 (0 = 빈 칸)
  final List<List<int>> puzzle;

  /// 정답
  final List<List<int>> solution;

  /// 현재 사용자 입력 상태
  final List<List<int>> currentBoard;

  /// 메모 (각 셀의 후보 숫자 집합)
  final List<List<Set<int>>> notes;

  /// 고정 숫자 여부 (퍼즐에서 미리 제공된 숫자)
  final List<List<bool>> isFixed;

  SudokuBoard({
    required List<List<int>> puzzle,
    required List<List<int>> solution,
    List<List<int>>? currentBoard,
    List<List<Set<int>>>? notes,
  })  : puzzle = _copyBoard(puzzle),
        solution = _copyBoard(solution),
        currentBoard = currentBoard != null ? _copyBoard(currentBoard) : _copyBoard(puzzle),
        notes = notes != null ? _copyNotes(notes) : _emptyNotes(),
        isFixed = _buildFixedMask(puzzle);

  /// 내부 전용 생성자 (이미 복사된 데이터를 받을 때 이중 복사 방지)
  SudokuBoard._internal({
    required this.puzzle,
    required this.solution,
    required this.currentBoard,
    required this.notes,
    required this.isFixed,
  });

  /// 보드 깊은 복사
  static List<List<int>> _copyBoard(List<List<int>> board) {
    return List.generate(9, (r) => List<int>.from(board[r]));
  }

  /// 빈 메모 생성
  static List<List<Set<int>>> _emptyNotes() {
    return List.generate(9, (_) => List.generate(9, (_) => <int>{}));
  }

  /// 고정 숫자 마스크 생성
  static List<List<bool>> _buildFixedMask(List<List<int>> puzzle) {
    return List.generate(
      9,
      (r) => List.generate(9, (c) => puzzle[r][c] != 0),
    );
  }

  /// 셀 값 입력
  SudokuBoard setValue(int row, int col, int value) {
    if (isFixed[row][col]) return this;
    final newBoard = _copyBoard(currentBoard);
    newBoard[row][col] = value;
    final newNotes = _copyNotes(notes);
    newNotes[row][col] = {};
    return _copyWith(currentBoard: newBoard, notes: newNotes);
  }

  /// 셀 값 삭제
  SudokuBoard clearValue(int row, int col) {
    if (isFixed[row][col]) return this;
    final newBoard = _copyBoard(currentBoard);
    newBoard[row][col] = 0;
    return _copyWith(currentBoard: newBoard);
  }

  /// 메모 토글
  SudokuBoard toggleNote(int row, int col, int value) {
    if (isFixed[row][col] || currentBoard[row][col] != 0) return this;
    final newNotes = _copyNotes(notes);
    if (newNotes[row][col].contains(value)) {
      newNotes[row][col].remove(value);
    } else {
      newNotes[row][col].add(value);
    }
    return _copyWith(notes: newNotes);
  }

  /// 정답 입력 시 관련 행/열/박스의 메모에서 해당 숫자 자동 제거
  SudokuBoard autoRemoveNotes(int row, int col, int value) {
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
    return _copyWith(notes: newNotes);
  }

  /// 모든 빈 칸에 가능한 후보 숫자를 자동으로 채움
  SudokuBoard autoFillNotes() {
    final newNotes = _emptyNotes();
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (currentBoard[r][c] != 0) continue;
        // 행, 열, 박스에 없는 숫자를 후보로 추가
        final used = <int>{};
        for (var i = 0; i < 9; i++) {
          if (currentBoard[r][i] > 0) used.add(currentBoard[r][i]);
          if (currentBoard[i][c] > 0) used.add(currentBoard[i][c]);
        }
        final boxRow = (r ~/ 3) * 3;
        final boxCol = (c ~/ 3) * 3;
        for (var br = boxRow; br < boxRow + 3; br++) {
          for (var bc = boxCol; bc < boxCol + 3; bc++) {
            if (currentBoard[br][bc] > 0) used.add(currentBoard[br][bc]);
          }
        }
        for (var n = 1; n <= 9; n++) {
          if (!used.contains(n)) newNotes[r][c].add(n);
        }
      }
    }
    return _copyWith(notes: newNotes);
  }

  /// 메모 상태를 전체 교체 (Undo 복원용)
  SudokuBoard restoreNotes(List<List<Set<int>>> restoredNotes) {
    return _copyWith(notes: _copyNotes(restoredNotes));
  }

  /// 완료 여부 판정
  bool get isCompleted {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (currentBoard[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  /// 특정 셀이 오답인지 확인
  bool isWrong(int row, int col) {
    final value = currentBoard[row][col];
    if (value == 0) return false;
    return value != solution[row][col];
  }

  /// 빈 셀 개수
  int get emptyCellCount {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (currentBoard[r][c] == 0) count++;
      }
    }
    return count;
  }

  /// 메모 깊은 복사 (public, 외부에서 Undo 백업용)
  static List<List<Set<int>>> copyNotesStatic(List<List<Set<int>>> notes) {
    return List.generate(
      9,
      (r) => List.generate(9, (c) => Set<int>.from(notes[r][c])),
    );
  }

  /// 메모 깊은 복사 (내부용)
  static List<List<Set<int>>> _copyNotes(List<List<Set<int>>> notes) {
    return copyNotesStatic(notes);
  }

  /// 내부 복사 (이미 복사된 데이터는 재복사하지 않음)
  SudokuBoard _copyWith({
    List<List<int>>? currentBoard,
    List<List<Set<int>>>? notes,
  }) {
    return SudokuBoard._internal(
      puzzle: puzzle,
      solution: solution,
      currentBoard: currentBoard ?? _copyBoard(this.currentBoard),
      notes: notes ?? _copyNotes(this.notes),
      isFixed: isFixed,
    );
  }

  /// JSON 직렬화 (DB 저장용)
  Map<String, dynamic> toJson() {
    return {
      'puzzle': puzzle.map((r) => r.join(',')).toList(),
      'solution': solution.map((r) => r.join(',')).toList(),
      'currentBoard': currentBoard.map((r) => r.join(',')).toList(),
      'notes': notes
          .map((r) => r.map((s) => s.join(',')).toList())
          .toList(),
    };
  }

  /// JSON 역직렬화
  factory SudokuBoard.fromJson(Map<String, dynamic> json) {
    List<List<int>> parseBoard(List<dynamic> data) {
      return data
          .map((r) => (r as String).split(',').map(int.parse).toList())
          .toList();
    }

    List<List<Set<int>>> parseNotes(List<dynamic> data) {
      return data.map((r) {
        return (r as List<dynamic>).map((s) {
          final str = s as String;
          if (str.isEmpty) return <int>{};
          return str.split(',').map(int.parse).toSet();
        }).toList();
      }).toList();
    }

    return SudokuBoard(
      puzzle: parseBoard(json['puzzle'] as List<dynamic>),
      solution: parseBoard(json['solution'] as List<dynamic>),
      currentBoard: parseBoard(json['currentBoard'] as List<dynamic>),
      notes: parseNotes(json['notes'] as List<dynamic>),
    );
  }
}
