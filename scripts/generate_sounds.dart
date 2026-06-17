// 사운드 자산 프로그래밍 합성 스크립트
// 외부 다운로드 대신 사인파 합성으로 7종 WAV 효과음을 생성한다.
// 라이센스: 자체 제작 (퍼블릭 도메인 동등)
//
// 실행: dart run scripts/generate_sounds.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 44100;

void main() {
  // 출력 디렉토리 생성
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // 7종 효과음 생성
  _writeWav('assets/sounds/click.wav', _click());
  _writeWav('assets/sounds/mistake.wav', _mistake());
  _writeWav('assets/sounds/line_complete.wav', _lineComplete());
  _writeWav('assets/sounds/game_complete.wav', _gameComplete());
  _writeWav('assets/sounds/badge.wav', _badge());
  _writeWav('assets/sounds/hint.wav', _hint());
  _writeWav('assets/sounds/pause.wav', _pause());

  print('Generated 7 sound files');
}

/// click: 1200Hz 사인파 + 빠른 페이드아웃 (60ms)
List<double> _click() {
  return _generate(60, (t) {
    final fade = math.exp(-t * 80);
    return math.sin(2 * math.pi * 1200 * t) * fade * 0.4;
  });
}

/// mistake: 200Hz + 400Hz 비프 (200ms)
List<double> _mistake() {
  return _generate(200, (t) {
    final fade = math.exp(-t * 5);
    final s1 = math.sin(2 * math.pi * 200 * t);
    final s2 = math.sin(2 * math.pi * 400 * t) * 0.5;
    return (s1 + s2) * fade * 0.3;
  });
}

/// line_complete: 800Hz + 1200Hz 화음 (300ms)
List<double> _lineComplete() {
  return _generate(300, (t) {
    final fade = math.exp(-t * 4);
    final s1 = math.sin(2 * math.pi * 800 * t);
    final s2 = math.sin(2 * math.pi * 1200 * t);
    return (s1 + s2) * 0.5 * fade * 0.4;
  });
}

/// game_complete: C5-E5-G5-C6 상승 음계 (1000ms)
List<double> _gameComplete() {
  final notes = [523.25, 659.25, 783.99, 1046.5]; // C5 E5 G5 C6
  return _generate(1000, (t) {
    const noteDuration = 0.25;
    final idx = (t / noteDuration).floor();
    if (idx >= notes.length) return 0.0;
    final localT = t - idx * noteDuration;
    final fade = math.exp(-localT * 4);
    return math.sin(2 * math.pi * notes[idx] * t) * fade * 0.4;
  });
}

/// badge: 1500Hz + 2000Hz 반짝 + 트레몰로 (500ms)
List<double> _badge() {
  return _generate(500, (t) {
    final fade = math.exp(-t * 3);
    final tremolo = 0.5 + 0.5 * math.sin(2 * math.pi * 8 * t);
    final s1 = math.sin(2 * math.pi * 1500 * t);
    final s2 = math.sin(2 * math.pi * 2000 * t) * 0.6;
    return (s1 + s2) * 0.5 * tremolo * fade * 0.4;
  });
}

/// hint: 400Hz→1600Hz 글리산도 (400ms)
List<double> _hint() {
  return _generate(400, (t) {
    final fade = math.exp(-t * 4);
    final freq = 400 + 1200 * t * 2.5; // 400 → 1600Hz
    return math.sin(2 * math.pi * freq * t) * fade * 0.4;
  });
}

/// pause: 600Hz 부드러운 톤 (300ms)
List<double> _pause() {
  return _generate(300, (t) {
    final envelope = t < 0.05 ? t / 0.05 : math.exp(-(t - 0.05) * 5);
    return math.sin(2 * math.pi * 600 * t) * envelope * 0.3;
  });
}

/// 지정 ms 동안 샘플 생성
List<double> _generate(int durationMs, double Function(double t) wave) {
  final samples = (sampleRate * durationMs / 1000).round();
  final result = List<double>.filled(samples, 0.0);
  for (var i = 0; i < samples; i++) {
    final t = i / sampleRate;
    var v = wave(t);
    if (v > 1.0) v = 1.0;
    if (v < -1.0) v = -1.0;
    result[i] = v;
  }
  return result;
}

/// PCM 16비트 모노 WAV 저장
void _writeWav(String path, List<double> samples) {
  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    pcm[i] = (samples[i] * 32767).round();
  }
  final dataBytes = pcm.buffer.asUint8List();
  final dataSize = dataBytes.length;

  final builder = BytesBuilder();
  // RIFF 헤더
  builder.add('RIFF'.codeUnits);
  builder.add(_int32LE(36 + dataSize));
  builder.add('WAVE'.codeUnits);
  // fmt 청크
  builder.add('fmt '.codeUnits);
  builder.add(_int32LE(16)); // fmt 청크 크기
  builder.add(_int16LE(1)); // PCM
  builder.add(_int16LE(1)); // 모노
  builder.add(_int32LE(sampleRate));
  builder.add(_int32LE(sampleRate * 2)); // byte rate
  builder.add(_int16LE(2)); // block align
  builder.add(_int16LE(16)); // bits per sample
  // data 청크
  builder.add('data'.codeUnits);
  builder.add(_int32LE(dataSize));
  builder.add(dataBytes);

  File(path).writeAsBytesSync(builder.toBytes());
  print('Wrote: $path ($dataSize bytes)');
}

Uint8List _int32LE(int v) {
  return Uint8List(4)
    ..[0] = v & 0xFF
    ..[1] = (v >> 8) & 0xFF
    ..[2] = (v >> 16) & 0xFF
    ..[3] = (v >> 24) & 0xFF;
}

Uint8List _int16LE(int v) {
  return Uint8List(2)
    ..[0] = v & 0xFF
    ..[1] = (v >> 8) & 0xFF;
}
