import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/scheduler.dart';

class PhysicsBallBackground extends StatefulWidget {
  final bool isDarkMode;

  const PhysicsBallBackground({super.key, required this.isDarkMode});

  @override
  State<PhysicsBallBackground> createState() =>
      _PhysicsBallBackgroundState();
}

class _PhysicsBallBackgroundState extends State<PhysicsBallBackground>
    with SingleTickerProviderStateMixin {
  static Offset _center = const Offset(0, 0);
  static Offset _velocity = const Offset(0.3, 0.2);
  static double _prevT = 0;
  static bool _hasInitFrame = false;
  static bool _initialized = false;

  static final Stopwatch _stopwatch = Stopwatch()..start();

  final Random _rand = Random();
  final double _bounds = 1.0;

  late StreamSubscription<AccelerometerEvent> _accelSub;
  double _ax = 0;
  double _ay = 0;

  @override
  void initState() {
    super.initState();

    if (!_initialized) {
      final angle = _rand.nextDouble() * 2 * pi;
      _velocity = Offset(cos(angle), sin(angle)) * 0.8;
      _initialized = true;
    }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        final t = (_stopwatch.elapsedMilliseconds % 12000) / 12000.0;

        if (!_hasInitFrame) {
          _prevT = t;
          _hasInitFrame = true;
        }

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });

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