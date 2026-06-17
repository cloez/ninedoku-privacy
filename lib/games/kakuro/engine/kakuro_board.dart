/// 카쿠로 보드 모델
/// - rows, cols: 격자 크기
/// - cells: 2D 배열을 1D로 펼친 KakuroCell 리스트
/// - 검은 셀(black): 힌트 표시용 (acrossHint, downHint)
/// - 흰 셀(white): 플레이어 입력 (value: 0=빈칸, 1~9)

/// 셀 타입
enum KakuroCellType { black, white }

/// 카쿠로 셀
class KakuroCell {
  /// 셀 타입 (검정/흰색)
  final KakuroCellType type;

  /// 흰 셀의 값 (0=빈칸, 1~9)
  final int value;

  /// 검은 셀: 오른쪽(가로) 블록 합계 힌트 (null=없음)
  final int? acrossHint;

  /// 검은 셀: 아래쪽(세로) 블록 합계 힌트 (null=없음)
  final int? downHint;

  const KakuroCell({
    required this.type,
    this.value = 0,
    this.acrossHint,
    this.downHint,
  });

  /// 검은 셀 (힌트 셀) 생성
  const KakuroCell.black({this.acrossHint, this.downHint})
      : type = KakuroCellType.black,
        value = 0;

  /// 흰 셀 생성
  const KakuroCell.white({this.value = 0})
      : type = KakuroCellType.white,
        acrossHint = null,
        downHint = null;

  /// 값 변경 (흰 셀 전용 — 새 셀 반환)
  KakuroCell withValue(int newValue) {
    if (type != KakuroCellType.white) return this;
    return KakuroCell(type: type, value: newValue);
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'type': type == KakuroCellType.black ? 'B' : 'W',
      if (type == KakuroCellType.white) 'v': value,
      if (acrossHint != null) 'a': acrossHint,
      if (downHint != null) 'd': downHint,
    };
  }

  /// JSON 역직렬화
  factory KakuroCell.fromJson(Map<String, dynamic> json) {
    final isBlack = json['type'] == 'B';
    if (isBlack) {
      return KakuroCell.black(
        acrossHint: json['a'] as int?,
        downHint: json['d'] as int?,
      );
    }
    return KakuroCell.white(value: json['v'] as int? ?? 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! KakuroCell) return false;
    return type == other.type &&
        value == other.value &&
        acrossHint == other.acrossHint &&
        downHint == other.downHint;
  }

  @override
  int get hashCode => Object.hash(type, value, acrossHint, downHint);
}

/// 카쿠로 블록 정보 (연속 white 셀 그룹)
class KakuroBlock {
  /// 블록 방향 (가로/세로)
  final bool isAcross;

  /// 힌트 합계
  final int sum;

  /// 블록에 포함된 셀 좌표 목록 [(row, col), ...]
  final List<(int, int)> cells;

  const KakuroBlock({
    required this.isAcross,
    required this.sum,
    required this.cells,
  });
}

/// 카쿠로 보드
class KakuroBoard {
  /// 행 수
  final int rows;

  /// 열 수
  final int cols;

  /// 셀 배열 (1차원, row * cols + col)
  final List<KakuroCell> cells;

  /// 고정 셀 인덱스 (초기에 주어진 값)
  final Set<int> fixed;

  /// 메모 (후보 숫자) — 셀 인덱스 → 후보 숫자 집합
  final Map<int, Set<int>> notes;

  KakuroBoard({
    required this.rows,
    required this.cols,
    required List<KakuroCell> cells,
    Set<int>? fixed,
    Map<int, Set<int>>? notes,
  })  : assert(cells.length == rows * cols, '셀 배열 길이가 rows*cols와 다릅니다'),
        cells = List<KakuroCell>.from(cells),
        fixed = fixed != null ? Set<int>.from(fixed) : {},
        notes = notes != null
            ? Map<int, Set<int>>.fromEntries(
                notes.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value))))
            : {};

  /// 셀 인덱스 계산
  int _idx(int row, int col) => row * cols + col;

  /// 셀 조회
  KakuroCell getCell(int row, int col) {
    _assertInBounds(row, col);
    return cells[_idx(row, col)];
  }

  /// 흰 셀의 값 조회 (검은 셀은 0)
  int getValue(int row, int col) {
    final cell = getCell(row, col);
    return cell.type == KakuroCellType.white ? cell.value : 0;
  }

  /// 흰 셀에 값 설정 (불변 — 새 보드 반환)
  KakuroBoard setValue(int row, int col, int value) {
    _assertInBounds(row, col);
    final idx = _idx(row, col);
    final cell = cells[idx];

    // 검은 셀이거나 고정 셀은 변경 불가
    if (cell.type != KakuroCellType.white) return this;
    if (fixed.contains(idx)) return this;

    final newCells = List<KakuroCell>.from(cells);
    newCells[idx] = cell.withValue(value);

    // 값을 넣으면 해당 셀의 메모 제거
    final newNotes = Map<int, Set<int>>.fromEntries(
        notes.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value))));
    if (value != 0) {
      newNotes.remove(idx);
    }

    return KakuroBoard(
      rows: rows,
      cols: cols,
      cells: newCells,
      fixed: fixed,
      notes: newNotes,
    );
  }

  /// 메모 토글 (불변 — 새 보드 반환)
  KakuroBoard toggleNote(int row, int col, int num) {
    _assertInBounds(row, col);
    assert(num >= 1 && num <= 9, '메모 숫자는 1~9 범위여야 합니다');

    final idx = _idx(row, col);
    final cell = cells[idx];
    if (cell.type != KakuroCellType.white) return this;
    if (fixed.contains(idx)) return this;
    if (cell.value != 0) return this; // 값이 있으면 메모 불가

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

    return KakuroBoard(
      rows: rows,
      cols: cols,
      cells: cells,
      fixed: fixed,
      notes: newNotes,
    );
  }

  /// 모든 흰 셀이 채워졌는지
  bool get isComplete {
    for (final cell in cells) {
      if (cell.type == KakuroCellType.white && cell.value == 0) return false;
    }
    return true;
  }

  /// 빈 흰 셀 개수
  int get emptyCellCount {
    var count = 0;
    for (final cell in cells) {
      if (cell.type == KakuroCellType.white && cell.value == 0) count++;
    }
    return count;
  }

  /// 채워진 흰 셀 개수
  int get filledCellCount {
    var count = 0;
    for (final cell in cells) {
      if (cell.type == KakuroCellType.white && cell.value != 0) count++;
    }
    return count;
  }

  /// 전체 흰 셀 개수
  int get totalWhiteCells {
    var count = 0;
    for (final cell in cells) {
      if (cell.type == KakuroCellType.white) count++;
    }
    return count;
  }

  /// 모든 블록(가로+세로) 추출
  List<KakuroBlock> get blocks {
    final result = <KakuroBlock>[];

    // 가로 블록: 검은 셀의 acrossHint → 오른쪽 연속 흰 셀
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cell = getCell(r, c);
        if (cell.type == KakuroCellType.black && cell.acrossHint != null) {
          final blockCells = <(int, int)>[];
          for (var cc = c + 1; cc < cols; cc++) {
            if (getCell(r, cc).type != KakuroCellType.white) break;
            blockCells.add((r, cc));
          }
          if (blockCells.isNotEmpty) {
            result.add(KakuroBlock(
              isAcross: true,
              sum: cell.acrossHint!,
              cells: blockCells,
            ));
          }
        }
      }
    }

    // 세로 블록: 검은 셀의 downHint → 아래쪽 연속 흰 셀
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cell = getCell(r, c);
        if (cell.type == KakuroCellType.black && cell.downHint != null) {
          final blockCells = <(int, int)>[];
          for (var rr = r + 1; rr < rows; rr++) {
            if (getCell(rr, c).type != KakuroCellType.white) break;
            blockCells.add((rr, c));
          }
          if (blockCells.isNotEmpty) {
            result.add(KakuroBlock(
              isAcross: false,
              sum: cell.downHint!,
              cells: blockCells,
            ));
          }
        }
      }
    }

    return result;
  }

  /// 특정 셀이 속한 블록들 반환
  List<KakuroBlock> blocksForCell(int row, int col) {
    return blocks.where((b) => b.cells.contains((row, col))).toList();
  }

  /// 깊은 복사
  KakuroBoard copyWith({
    int? rows,
    int? cols,
    List<KakuroCell>? cells,
    Set<int>? fixed,
    Map<int, Set<int>>? notes,
  }) {
    return KakuroBoard(
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      cells: cells ?? List<KakuroCell>.from(this.cells),
      fixed: fixed ?? Set<int>.from(this.fixed),
      notes: notes ??
          Map<int, Set<int>>.fromEntries(
              this.notes.entries.map((e) => MapEntry(e.key, Set<int>.from(e.value)))),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    final notesJson = <String, dynamic>{};
    for (final entry in notes.entries) {
      notesJson['${entry.key}'] = entry.value.toList();
    }
    return {
      'rows': rows,
      'cols': cols,
      'cells': cells.map((c) => c.toJson()).toList(),
      'fixed': fixed.toList(),
      'notes': notesJson,
    };
  }

  /// JSON 역직렬화
  factory KakuroBoard.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    final cellsList = (json['cells'] as List<dynamic>)
        .map((c) => KakuroCell.fromJson(c as Map<String, dynamic>))
        .toList();
    final fixedList = (json['fixed'] as List<dynamic>?)?.cast<int>() ?? [];

    final notesJson = json['notes'] as Map<String, dynamic>? ?? {};
    final notes = <int, Set<int>>{};
    for (final entry in notesJson.entries) {
      final idx = int.parse(entry.key);
      final values = (entry.value as List<dynamic>).cast<int>().toSet();
      notes[idx] = values;
    }

    return KakuroBoard(
      rows: rows,
      cols: cols,
      cells: cellsList,
      fixed: Set<int>.from(fixedList),
      notes: notes,
    );
  }

  /// 범위 검증
  void _assertInBounds(int row, int col) {
    assert(row >= 0 && row < rows, '행 인덱스 범위 초과: $row');
    assert(col >= 0 && col < cols, '열 인덱스 범위 초과: $col');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! KakuroBoard) return false;
    if (rows != other.rows || cols != other.cols) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != other.cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(rows, cols, Object.hashAll(cells));

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cell = getCell(r, c);
        if (cell.type == KakuroCellType.black) {
          final d = cell.downHint?.toString() ?? '.';
          final a = cell.acrossHint?.toString() ?? '.';
          buffer.write('[$d\\$a]');
        } else {
          buffer.write(cell.value == 0 ? '  _  ' : '  ${cell.value}  ');
        }
        if (c < cols - 1) buffer.write(' ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
