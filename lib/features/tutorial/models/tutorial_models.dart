import 'package:flutter/material.dart';

/// 튜토리얼 일러스트 형식 — 정적 아이콘 또는 미니 보드
sealed class TutorialIllustration {
  const TutorialIllustration();
}

/// 아이콘 일러스트
class IconIllustration extends TutorialIllustration {
  final IconData icon;
  const IconIllustration(this.icon);
}

/// 미니 보드 일러스트 (3×3, 4×4, 5×5 축약 보드)
class MiniBoardIllustration extends TutorialIllustration {
  final String gameId;
  // 보드 값. null=빈 칸. 0/1은 이진 게임용. 숫자는 일반 게임용.
  final List<List<int?>> board;
  // 강조 셀
  final List<CellHighlight> highlights;
  // 오버레이 (✓/⚠ 등)
  final OverlayKind? overlay;

  const MiniBoardIllustration({
    required this.gameId,
    required this.board,
    this.highlights = const [],
    this.overlay,
  });
}

/// 셀 강조 정보
class CellHighlight {
  final int row;
  final int col;
  final HighlightStyle style;
  const CellHighlight(this.row, this.col, this.style);
}

/// 강조 스타일
enum HighlightStyle { info, success, error, arrow, target }

/// 오버레이 종류
enum OverlayKind { okMark, errorMark, arrow, pulse }

/// 셀 좌표 타겟
class CellTarget {
  final int row;
  final int col;
  const CellTarget(this.row, this.col);
}

/// 인터랙티브 연습 정의 (S6 단계 — 현재는 스도쿠만)
class InteractivePractice {
  final String gameId;
  final List<List<int?>> initialBoard;
  final CellTarget target;
  final int correctValue;
  final String hintKey;
  final int maxWrongAttempts;

  const InteractivePractice({
    required this.gameId,
    required this.initialBoard,
    required this.target,
    required this.correctValue,
    required this.hintKey,
    this.maxWrongAttempts = 3,
  });
}

/// 단일 튜토리얼 단계
class TutorialStep {
  final String titleKey;
  final String descriptionKey;
  final TutorialIllustration illustration;
  final InteractivePractice? practice;

  const TutorialStep({
    required this.titleKey,
    required this.descriptionKey,
    required this.illustration,
    this.practice,
  });
}

/// 게임별 튜토리얼 정의
class GameTutorial {
  final String gameId;
  final List<TutorialStep> steps;

  const GameTutorial({required this.gameId, required this.steps});
}

/// 튜토리얼 진행 단계 (UI 상태머신)
enum TutorialPhase {
  reading, // 텍스트 + 일러스트 표시 중
  practiceWaiting, // S6: 사용자 입력 대기
  practiceCorrect, // 정답 입력 직후
  practiceWrong, // 오답 입력 직후
  practiceRevealed, // "정답 보기" 클릭 후
  completed, // 마지막 단계 완료
}
