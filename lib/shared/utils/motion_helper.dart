import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 글로벌 "효과 줄이기" 플래그.
/// main.dart 부팅 시점과 설정 토글 변경 시 [setReduceEffects]로 갱신.
bool _globalReduceEffects = false;

/// 글로벌 효과 줄이기 플래그 설정.
/// 위젯이 prefs를 직접 전달하지 못해도 앱 설정 토글이 반영되도록 한다.
void setReduceEffects(bool value) {
  _globalReduceEffects = value;
}

/// 현재 글로벌 효과 줄이기 플래그 조회.
bool getReduceEffects() => _globalReduceEffects;

/// 모션 배율 헬퍼.
///
/// - 시스템 접근성 "애니메이션 줄이기" 활성 시 0.0 (효과 스킵)
/// - 사용자 설정 "효과 줄이기" 활성 시 0.3 (prefs 인자 또는 글로벌 플래그)
/// - 기본 1.0
double motionScale(BuildContext context, {SharedPreferences? prefs}) {
  if (MediaQuery.disableAnimationsOf(context)) return 0.0;
  // prefs 인자가 있으면 우선 적용, 없으면 글로벌 플래그 사용
  final reduce = prefs != null
      ? (prefs.getBool('reduce_effects') ?? false)
      : _globalReduceEffects;
  if (reduce) return 0.3;
  return 1.0;
}

/// duration 스케일 적용.
/// motionScale == 0 이면 Duration.zero 반환.
Duration scaledDuration(BuildContext context, int ms,
    {SharedPreferences? prefs}) {
  final scale = motionScale(context, prefs: prefs);
  if (scale == 0.0) return Duration.zero;
  return Duration(milliseconds: (ms * scale).round());
}
