import 'package:audioplayers/audioplayers.dart';

/// 효과음 매니저 — 싱글톤
///
/// - 7종 효과음을 각각 전용 AudioPlayer 인스턴스로 관리
/// - 50ms throttle 로 같은 키 연속 재생 방지
/// - 자산 누락 / 재생 실패 시 silent fail (게임 진행 영향 없음)
class SoundManager {
  static final SoundManager _instance = SoundManager._();
  factory SoundManager() => _instance;
  SoundManager._();

  // 사운드 키 상수 (오타 방지)
  static const String kClick = 'click';
  static const String kMistake = 'mistake';
  static const String kLineComplete = 'line_complete';
  static const String kGameComplete = 'game_complete';
  static const String kBadge = 'badge';
  static const String kHint = 'hint';
  static const String kPause = 'pause';

  final Map<String, AudioPlayer> _players = {};
  final Map<String, DateTime> _lastPlayed = {};
  bool _enabled = true;
  bool _preloaded = false;

  // 키 → 에셋 경로 매핑 (AssetSource 는 assets/ prefix 자동)
  static const Map<String, String> _sounds = {
    kClick: 'sounds/click.wav',
    kMistake: 'sounds/mistake.wav',
    kLineComplete: 'sounds/line_complete.wav',
    kGameComplete: 'sounds/game_complete.wav',
    kBadge: 'sounds/badge.wav',
    kHint: 'sounds/hint.wav',
    kPause: 'sounds/pause.wav',
  };

  bool get enabled => _enabled;
  bool get isPreloaded => _preloaded;

  /// 앱 시작 시 호출 — 모든 효과음을 미리 로드한다.
  /// 자산 누락 시 silent fail.
  Future<void> preload() async {
    if (_preloaded) return;
    for (final entry in _sounds.entries) {
      try {
        final player = AudioPlayer(playerId: 'sfx_${entry.key}');
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value));
        _players[entry.key] = player;
      } catch (_) {
        // 자산 누락 / 로드 실패 시 무시
      }
    }
    _preloaded = true;
  }

  /// 효과음 재생 (silent fail).
  ///
  /// - [_enabled] false 시 무시
  /// - 같은 키 50ms throttle
  /// - [volume] 0.0~1.0 (선택)
  Future<void> play(String key, {double volume = 1.0}) async {
    if (!_enabled) return;

    // throttle: 같은 키 50ms 간격
    final now = DateTime.now();
    final last = _lastPlayed[key];
    if (last != null && now.difference(last).inMilliseconds < 50) return;
    _lastPlayed[key] = now;

    final player = _players[key];
    if (player == null) return;
    try {
      await player.stop();
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.resume();
    } catch (_) {
      // 재생 실패 silent fail
    }
  }

  /// 사용자 설정 토글 — 비활성화 시 모든 재생 중인 사운드 정지.
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      for (final p in _players.values) {
        try {
          p.stop();
        } catch (_) {}
      }
    }
  }

  /// 앱 백그라운드 진입 등 일시 정지.
  void stopAll() {
    for (final p in _players.values) {
      try {
        p.stop();
      } catch (_) {}
    }
  }

  /// 리소스 정리.
  Future<void> dispose() async {
    for (final p in _players.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _players.clear();
    _lastPlayed.clear();
    _preloaded = false;
  }
}
