import 'package:flutter/services.dart';
import '../settings/settings_service.dart';

/// 사운드/진동 피드백 유틸리티
class FeedbackService {
  final SettingsService _settings;

  FeedbackService(this._settings);

  /// 숫자 입력 시 피드백
  void onNumberInput() {
    _playClick();
    _vibrate(HapticFeedbackType.light);
  }

  /// 실수 발생 시 피드백
  void onMistake() {
    _vibrate(HapticFeedbackType.heavy);
  }

  /// 게임 완료 시 피드백
  void onGameComplete() {
    _vibrate(HapticFeedbackType.medium);
  }

  /// 배지 획득 시 피드백
  void onBadgeEarned() {
    _vibrate(HapticFeedbackType.medium);
  }

  /// 힌트 사용 시 피드백
  void onHintUsed() {
    _vibrate(HapticFeedbackType.selection);
  }

  /// 셀 선택 시 피드백
  void onCellSelect() {
    _vibrate(HapticFeedbackType.selection);
  }

  /// 시스템 클릭 사운드 재생
  void _playClick() {
    if (!_settings.soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// 햅틱 진동
  void _vibrate(HapticFeedbackType type) {
    if (!_settings.vibrationEnabled) return;
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
    }
  }
}

/// 진동 강도
enum HapticFeedbackType { light, medium, heavy, selection }
