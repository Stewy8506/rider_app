

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PhysicsBallBackground extends StatefulWidget {
  final bool isDarkMode;

  const PhysicsBallBackground({super.key, required this.isDarkMode});

  @override
  State<PhysicsBallBackground> createState() =>
      _PhysicsBallBackgroundState();
}

class _PhysicsBallBackgroundState extends State<PhysicsBallBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Offset _center = const Offset(0, 0);
  Offset _velocity = const Offset(0.3, 0.2);
  double _prevT = 0;

  final Random _rand = Random();
  final double _bounds = 1.0;

  late StreamSubscription<AccelerometerEvent> _accelSub;
  double _ax = 0;
  double _ay = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final angle = _rand.nextDouble() * 2 * pi;
    _velocity = Offset(cos(angle), sin(angle)) * 0.8;

    _accelSub = accelerometerEventStream().listen((event) {
      _ax = _ax * 0.8 + event.x * 0.2;
      _ay = _ay * 0.8 + event.y * 0.2;

      final dx = -_ax;
      final dy = _ay;

      _velocity =
          Offset(_velocity.dx + dx * 0.004, _velocity.dy + dy * 0.004);
    });
  }

  @override
  void dispose() {
    _accelSub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        double dt = t - _prevT;
        if (dt < 0) dt += 1;
        _prevT = t;

        _velocity *= 0.999;
        _center += _velocity * dt * 2;

        const restitution = 0.85;

        if (_center.dx > _bounds) {
          _center = Offset(_bounds, _center.dy);
          _velocity =
              Offset(-_velocity.dx.abs() * restitution, _velocity.dy);
        } else if (_center.dx < -_bounds) {
          _center = Offset(-_bounds, _center.dy);
          _velocity =
              Offset(_velocity.dx.abs() * restitution, _velocity.dy);
        }

        if (_center.dy > _bounds) {
          _center = Offset(_center.dx, _bounds);
          _velocity =
              Offset(_velocity.dx, -_velocity.dy.abs() * restitution);
        } else if (_center.dy < -_bounds) {
          _center = Offset(_center.dx, -_bounds);
          _velocity =
              Offset(_velocity.dx, _velocity.dy.abs() * restitution);
        }

        const minSpeed = 0.45;
        final speed = _velocity.distance;
        if (speed < minSpeed) {
          final dir = speed > 0 ? _velocity / speed : const Offset(1, 0);
          _velocity = dir * minSpeed;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(_center.dx, _center.dy),
              radius: 1,
              colors: widget.isDarkMode
                  ? [
                      Colors.grey.withAlpha(20),
                      Colors.white.withAlpha(50),
                      Colors.black.withAlpha(5),
                    ]
                  : [
                      Colors.white.withAlpha(150),
                      Colors.white.withAlpha(110),
                      Colors.white,
                    ],
            ),
          ),
        );
      },
    );
  }
}