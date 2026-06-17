import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/storage/storage_providers.dart';

/// 스플래시 화면 — K를 이루는 4개의 막대가 사방에서 회전하며 모여 K를 완성하고,
/// 잠시 멈춘 뒤 다시 회전하며 사방으로 흩어지면서 다음 화면으로 전환.
///
/// 타임라인 (총 3000ms):
/// - 0     ~ 1100ms : 모임  — easeOutBack(overshoot)으로 탄력있게 진입, ~270도 회전
/// - 1100  ~ 1900ms : 정지  — K 완성 펄스 (1.0 → 1.07 → 1.0)
/// - 1900  ~ 3000ms : 흩어짐 — easeInBack(반대 방향 탄성)으로 흩어짐, ~200도 회전, 페이드아웃
/// - 3000ms        : 다음 라우트로 전환
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 마크 표시 사이즈 (조각 PNG 캔버스 사이즈와 동일하게 컨테이너)
  static const double _markSize = 320.0;
  // 사방 진입/이탈 거리 (화면 가장자리 근처 — 초반 가시성 확보)
  static const double _flyDist = 480.0;

  // 페이즈 경계
  static const double _phaseGather = 0.367; // 0 ~ 1100ms
  static const double _phaseHold = 0.633;   // 1100 ~ 1900ms (~800ms 정지)
  // 0.633 ~ 1.0 흩어짐 (~1100ms)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateNext();
      }
    });

    _controller.forward();
  }

  void _navigateNext() {
    // 시나리오:
    // - 최초 시작 (isFirstLaunch): 허브로 + 플래그 false 처리
    // - 두 번째 이상 시작: 마지막 게임 home으로 (없으면 허브)
    // 온보딩 라우트는 제거됨 — 첫 진입도 곧바로 허브
    final settings = ref.read(settingsProvider);
    final String next;
    if (settings.isFirstLaunch) {
      // 첫 실행: 다음부터는 last 게임으로 가도록 플래그 해제
      settings.setFirstLaunchDone();
      next = AppRoutes.hub;
    } else {
      next = settings.lastGameRoute ?? AppRoutes.hub;
    }
    try {
      context.go(next);
    } catch (_) {
      context.go(AppRoutes.hub);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 조각 위치 보간
  Offset _pieceOffset(Offset away, double t) {
    if (t < _phaseGather) {
      final p = (t / _phaseGather).clamp(0.0, 1.0);
      // easeOutBack — overshoot로 살짝 튕기며 도착
      final eased = Curves.easeOutBack.transform(p);
      return Offset.lerp(away, Offset.zero, eased)!;
    } else if (t < _phaseHold) {
      return Offset.zero;
    } else {
      final p = ((t - _phaseHold) / (1.0 - _phaseHold)).clamp(0.0, 1.0);
      // easeInCubic — 흩어짐의 일관된 가속 (Back은 anticipation이 있어 어색함)
      final eased = Curves.easeInCubic.transform(p);
      return Offset.lerp(Offset.zero, away, eased)!;
    }
  }

  /// 조각 회전 보간 (라디안)
  double _pieceRotation(double startRot, double endRot, double t) {
    if (t < _phaseGather) {
      final p = (t / _phaseGather).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(p);
      return startRot * (1 - eased);
    } else if (t < _phaseHold) {
      return 0;
    } else {
      final p = ((t - _phaseHold) / (1.0 - _phaseHold)).clamp(0.0, 1.0);
      final eased = Curves.easeInCubic.transform(p);
      return endRot * eased;
    }
  }

  /// 전체 마크 스케일 (모일 때 작게 시작 → 1.0 / 정지 시 펄스 / 흩어질 때 점점 확대)
  double _markScale(double t) {
    if (t < _phaseGather) {
      final p = (t / _phaseGather).clamp(0.0, 1.0);
      final eased = Curves.easeOutBack.transform(p);
      return 0.5 + 0.5 * eased;
    } else if (t < _phaseHold) {
      final p = (t - _phaseGather) / (_phaseHold - _phaseGather);
      // 0 → 1 → 0 sin 곡선 (peak at 0.5)
      final s = math.sin(p * math.pi);
      return 1.0 + 0.07 * s;
    } else {
      final p = ((t - _phaseHold) / (1.0 - _phaseHold)).clamp(0.0, 1.0);
      // 흩어질 때 살짝 확대 (날아가는 느낌 강조 — 과도하면 겹침 발생)
      return 1.0 + 0.10 * Curves.easeInQuad.transform(p);
    }
  }

  /// 알파 — 빠른 페이드인 + 흩어짐 페이드아웃 (70%까지만, 흩어지는 4조각이 식별되도록)
  double _alpha(double t) {
    if (t < 0.04) {
      return (t / 0.04).clamp(0.0, 1.0);
    }
    if (t < _phaseHold) return 1.0;
    final p = ((t - _phaseHold) / (1.0 - _phaseHold)).clamp(0.0, 1.0);
    return (1.0 - p * 0.70).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122B5E),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final alpha = _alpha(t);
          final scale = _markScale(t);

          // 각 조각의 사방 진입/이탈 방향 — 단순 대각선이 아니라 약간 비스듬히
          const blueAway = Offset(-_flyDist, -_flyDist * 0.85);   // 좌상에서
          const orangeAway = Offset(_flyDist, -_flyDist);         // 우상에서
          const purpleAway = Offset(-_flyDist * 0.9, _flyDist);   // 좌하에서
          const greenAway = Offset(_flyDist, _flyDist * 0.85);    // 우하에서

          // 각 조각의 진입/이탈 회전 — 큰 각도로 다이나믹
          const blueStartRot = -math.pi * 1.5;    // -270도
          const blueEndRot = math.pi * 1.1;       // +198도
          const orangeStartRot = math.pi * 1.5;   // +270도
          const orangeEndRot = -math.pi * 1.1;    // -198도
          const purpleStartRot = math.pi * 1.2;   // +216도
          const purpleEndRot = -math.pi * 1.3;    // -234도
          const greenStartRot = -math.pi * 1.2;   // -216도
          const greenEndRot = math.pi * 1.3;      // +234도

          return Center(
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: _markSize,
                height: _markSize,
                child: Stack(
                  children: [
                    _piece(
                      'assets/splash_piece_blue.png',
                      _pieceOffset(blueAway, t),
                      _pieceRotation(blueStartRot, blueEndRot, t),
                      alpha,
                    ),
                    _piece(
                      'assets/splash_piece_purple.png',
                      _pieceOffset(purpleAway, t),
                      _pieceRotation(purpleStartRot, purpleEndRot, t),
                      alpha,
                    ),
                    _piece(
                      'assets/splash_piece_orange.png',
                      _pieceOffset(orangeAway, t),
                      _pieceRotation(orangeStartRot, orangeEndRot, t),
                      alpha,
                    ),
                    _piece(
                      'assets/splash_piece_green.png',
                      _pieceOffset(greenAway, t),
                      _pieceRotation(greenStartRot, greenEndRot, t),
                      alpha,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _piece(String asset, Offset offset, double rotation, double alpha) {
    return Positioned.fill(
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: alpha,
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
