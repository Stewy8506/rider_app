import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PhysicsBallBackground extends StatefulWidget {
  final bool isDarkMode;

  const PhysicsBallBackground({super.key, required this.isDarkMode});

  @override
  State<PhysicsBallBackground> createState() => _PhysicsBallBackgroundState();
}

class _PhysicsBallBackgroundState extends State<PhysicsBallBackground>
    with SingleTickerProviderStateMixin {
  static Offset _center = const Offset(0, 0);
  static Offset _velocity = const Offset(0.3, 0.2);
  static double _prevT = 0;
  static bool _hasInitFrame = false;
  static bool _initialized = false;
  static double _rotation = 0;

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

      _velocity = Offset(_velocity.dx + dx * 0.004, _velocity.dy + dy * 0.004);
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
          _velocity = Offset(-_velocity.dx.abs() * restitution, _velocity.dy);
        } else if (_center.dx < -_bounds) {
          _center = Offset(-_bounds, _center.dy);
          _velocity = Offset(_velocity.dx.abs() * restitution, _velocity.dy);
        }

        if (_center.dy > _bounds) {
          _center = Offset(_center.dx, _bounds);
          _velocity = Offset(_velocity.dx, -_velocity.dy.abs() * restitution);
        } else if (_center.dy < -_bounds) {
          _center = Offset(_center.dx, -_bounds);
          _velocity = Offset(_velocity.dx, _velocity.dy.abs() * restitution);
        }

        const minSpeed = 0.45;
        final speed = _velocity.distance;
        if (speed < minSpeed) {
          final dir = speed > 0 ? _velocity / speed : const Offset(1, 0);
          _velocity = dir * minSpeed;
        }

        _rotation += _velocity.dx * dt * 5;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });

        final double wheelSize = 250.0;

        final tireColor = widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.85);

        final rimColor = widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.grey.shade700;

        final spokeColor = widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.grey.shade500;

        final hubColor = widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.black87;

        // Edit this variable to change the blur intensity of the background wheel!
        final double backgroundBlurAmount = 0;

        // Edit this variable to control the dimming/brightness of the background!
        // 0.0 = bright (default), 1.0 = completely black
        final double backgroundDimOpacity = 0.4;

        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: widget.isDarkMode
                    ? Colors.transparent
                    : const Color(0xFFF0F0F0),
                child: Transform.translate(
                  offset: Offset(
                    _center.dx * (screenWidth - wheelSize) / 2,
                    _center.dy * (screenHeight - wheelSize) / 2,
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: _rotation,
                      // RepaintBoundary isolates the incredibly heavy vector drawing and blur!
                      // Flutter caches this as a texture, so animating it costs ZERO rendering compute!
                      child: RepaintBoundary(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: backgroundBlurAmount,
                            sigmaY: backgroundBlurAmount,
                          ),
                          child: SizedBox(
                            width: wheelSize,
                            height: wheelSize,
                            child: Stack(
                              children: [
                                // Subtle Ambient glow radiating from the wheel
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.isDarkMode
                                              ? Colors.white.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          blurRadius: wheelSize * 0.15,
                                          spreadRadius: wheelSize * 0.10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // The complex wheel geometries
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: BikeWheelPainter(
                                      tireColor: tireColor,
                                      rimColor: rimColor,
                                      spokeColor: spokeColor,
                                      hubColor: hubColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Translucent overlay to control background brightness/wash
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: widget.isDarkMode
                      ? Colors.black.withValues(alpha: backgroundDimOpacity)
                      : Colors.white.withValues(alpha: backgroundDimOpacity),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BikeWheelPainter extends CustomPainter {
  final Color tireColor;
  final Color rimColor;
  final Color spokeColor;
  final Color hubColor;

  BikeWheelPainter({
    required this.tireColor,
    required this.rimColor,
    required this.spokeColor,
    required this.hubColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // --- Geometries ---
    // To make the tire thick without shrinking the rim, we grow the tire completely OUTWARD
    final rimOuterRadius =
        radius * 0.80; // Locked to its beautiful original geometry

    final tireThickness = radius * 0.28; // Massive thickness
    final tireOuterRadius =
        rimOuterRadius +
        tireThickness; // Pops outside the bounding box slightly
    final innerTireRadius = rimOuterRadius;

    final rimThickness = radius * 0.08;
    final innerRimRadius = innerTireRadius - rimThickness;

    final hubRadius = radius * 0.14;

    // Floating Disk Brake Geometries
    final rotorOuterRadius = radius * 0.55;
    final rotorInnerRadius = radius * 0.38;
    final brakeRotorThickness = rotorOuterRadius - rotorInnerRadius;
    final rotorCenterRadius = rotorInnerRadius + brakeRotorThickness / 2;

    final carrierOuterRadius = rotorInnerRadius;
    final carrierInnerRadius = radius * 0.16;

    // --- 1. Background Structure (Tire, Rim, Alloy Spokes) ---
    // Massive Sportbike Tire
    canvas.drawCircle(
      center,
      tireOuterRadius - tireThickness / 2,
      Paint()
        ..color = tireColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = tireThickness,
    );

    // Minimalist Sportbike Tire Treads (Like Pirelli Diablo Rosso)
    final int numTreads = 16;

    final treadPaintPrimary = Paint()
      ..color = Colors.black
          .withValues(alpha: 0.45) // Subtle shadow slash
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.008
      ..strokeCap = StrokeCap.round;

    final treadPaintSecondary = Paint()
      ..color = Colors.black
          .withValues(alpha: 0.3) // Faint inner slash
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.005
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < numTreads; i++) {
      final angle = (i * pi * 2) / numTreads;

      // Primary short diagonal slashes near the edge
      final primaryStartOuterR = tireOuterRadius - tireThickness * 0.02;
      final primaryEndInnerR = tireOuterRadius - tireThickness * 0.15;

      final Path treadPath = Path();
      for (double t = 0; t <= 1.0; t += 0.5) {
        final currentR =
            primaryStartOuterR - (primaryStartOuterR - primaryEndInnerR) * t;
        final currentAngle = angle + (t * 0.06);

        final px = center.dx + cos(currentAngle) * currentR;
        final py = center.dy + sin(currentAngle) * currentR;

        if (t == 0) {
          treadPath.moveTo(px, py);
        } else {
          treadPath.lineTo(px, py);
        }
      }
      canvas.drawPath(treadPath, treadPaintPrimary);

      // Tiny secondary dash further inward
      final secondaryStartR = tireOuterRadius - tireThickness * 0.18;
      final secondaryEndR = tireOuterRadius - tireThickness * 0.28;
      final secondaryPath = Path();
      for (double t = 0; t <= 1.0; t += 1.0) {
        final currentR =
            secondaryStartR - (secondaryStartR - secondaryEndR) * t;
        final currentAngle = angle + 0.05 + (t * 0.03);

        final px = center.dx + cos(currentAngle) * currentR;
        final py = center.dy + sin(currentAngle) * currentR;

        if (t == 0) {
          secondaryPath.moveTo(px, py);
        } else {
          secondaryPath.lineTo(px, py);
        }
      }
      canvas.drawPath(secondaryPath, treadPaintSecondary);
    }

    // Sidewall Embossed Ring (Simulates text/branding ridges on sport tires)
    canvas.drawCircle(
      center,
      tireOuterRadius - tireThickness * 0.45,
      Paint()
        ..color = rimColor
            .withValues(alpha: rimColor.a * 0.03) // Very faint light catch
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.003,
    );
    canvas.drawCircle(
      center,
      tireOuterRadius - tireThickness * 0.47,
      Paint()
        ..color = Colors.black
            .withValues(alpha: 0.2) // Very faint shadow ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.004,
    );

    // Tire Sidewall Edge Separator
    canvas.drawCircle(
      center,
      tireOuterRadius - tireThickness * 0.65,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.004,
    );

    // Deep Tire inner bead lip meeting the rim
    canvas.drawCircle(
      center,
      innerTireRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.015,
    );

    // Deep Alloy Rim Base
    canvas.drawCircle(
      center,
      innerTireRadius - rimThickness / 2,
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimThickness,
    );
    canvas.drawCircle(
      center,
      innerRimRadius,
      Paint()
        ..color = tireColor.withValues(alpha: tireColor.a * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.015,
    );

    // Base 5-Spoke Wheel underneath everything
    final int numSpokes = 5;
    for (int i = 0; i < numSpokes; i++) {
      final angle = (i * pi * 2) / numSpokes;
      final start = Offset(
        center.dx + cos(angle) * hubRadius,
        center.dy + sin(angle) * hubRadius,
      );
      final end = Offset(
        center.dx + cos(angle) * innerRimRadius,
        center.dy + sin(angle) * innerRimRadius,
      );

      // Massive cast spoke
      canvas.drawPath(
        Path()
          ..moveTo(
            center.dx + cos(angle - 0.1) * hubRadius,
            center.dy + sin(angle - 0.1) * hubRadius,
          )
          ..lineTo(
            center.dx + cos(angle - 0.04) * innerRimRadius,
            center.dy + sin(angle - 0.04) * innerRimRadius,
          )
          ..lineTo(
            center.dx + cos(angle + 0.04) * innerRimRadius,
            center.dy + sin(angle + 0.04) * innerRimRadius,
          )
          ..lineTo(
            center.dx + cos(angle + 0.1) * hubRadius,
            center.dy + sin(angle + 0.1) * hubRadius,
          )
          ..close(),
        Paint()
          ..color = spokeColor
          ..style = PaintingStyle.fill,
      );

      // Edge catching light shadow
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = tireColor.withValues(alpha: tireColor.a * 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.03,
      );
    }

    // --- 2. Floating Disk Brake Rotor (Steel) ---
    // Push the rotor color slightly brighter than the rim to make it pop distinctively
    final brightRotorColor = Color.lerp(
      rimColor,
      Colors.white,
      0.3,
    )!.withValues(alpha: (rimColor.a * 1.3).clamp(0.0, 1.0));

    // Rotor backing shadow
    canvas.drawCircle(
      center,
      rotorCenterRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = brakeRotorThickness + radius * 0.01,
    );

    // Solid Steel ring
    canvas.drawCircle(
      center,
      rotorCenterRadius,
      Paint()
        ..color = brightRotorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = brakeRotorThickness,
    );

    // High-contrast scoring / Wear lines on the rotor
    final scoreColor = Colors.black.withValues(
      alpha: 0.4,
    ); // Force dark lines for extreme contrast!
    canvas.drawCircle(
      center,
      rotorCenterRadius - brakeRotorThickness * 0.35,
      Paint()
        ..color = scoreColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.002,
    );
    canvas.drawCircle(
      center,
      rotorCenterRadius - brakeRotorThickness * 0.15,
      Paint()
        ..color = scoreColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.003,
    );
    canvas.drawCircle(
      center,
      rotorCenterRadius + brakeRotorThickness * 0.1,
      Paint()
        ..color = scoreColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.001,
    );
    canvas.drawCircle(
      center,
      rotorCenterRadius + brakeRotorThickness * 0.3,
      Paint()
        ..color = scoreColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.004,
    );

    // Sweeping cross-drilled cooling holes
    final int numHoleGroups = 20;
    final holePaint = Paint()
      ..color = Colors.black
          .withValues(
            alpha: 0.65,
          ) // Deep dark punch-out effect ensuring holes are perfectly visible
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numHoleGroups; i++) {
      final groupAngle = (i * pi * 2) / numHoleGroups;

      // 3 sweeping holes per drill matrix
      for (int j = 0; j < 3; j++) {
        final rOffset = -0.35 + (j * 0.35);
        final holeR = rotorCenterRadius + (brakeRotorThickness / 2) * rOffset;

        final holeAngle = groupAngle + (j * 0.12);

        final pos = Offset(
          center.dx + cos(holeAngle) * holeR,
          center.dy + sin(holeAngle) * holeR,
        );

        canvas.drawCircle(pos, radius * 0.012, holePaint);
      }
    }

    // --- 3. Brake Carrier (Monochrome Integration) ---
    // Push the carrier darker so it sharply highlights against the bright rotor
    final carrierColor = hubColor.withValues(
      alpha: (hubColor.a * 0.5).clamp(0.0, 1.0),
    );

    // Carrier Outer ring (where bobbins mount)
    canvas.drawCircle(
      center,
      carrierOuterRadius - radius * 0.015,
      Paint()
        ..color = carrierColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.02,
    );
    // Carrier Inner ring (where axle mounts)
    canvas.drawCircle(
      center,
      carrierInnerRadius,
      Paint()
        ..color = carrierColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.04,
    );

    // Thick custom arms of the carrier
    final int numCarrierArms = 6;
    for (int i = 0; i < numCarrierArms; i++) {
      final angle = (i * pi * 2) / numCarrierArms;

      final innerStart = Offset(
        center.dx + cos(angle) * carrierInnerRadius,
        center.dy + sin(angle) * carrierInnerRadius,
      );
      final outerEnd = Offset(
        center.dx + cos(angle + 0.25) * carrierOuterRadius,
        center.dy + sin(angle + 0.25) * carrierOuterRadius,
      );

      // Draw the carrier arm
      canvas.drawLine(
        innerStart,
        outerEnd,
        Paint()
          ..color = carrierColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.06
          ..strokeCap = StrokeCap.round,
      );

      // Machine cutout (weight reduction) inside the arm!
      canvas.drawLine(
        innerStart,
        outerEnd,
        Paint()
          ..color = Colors.black
              .withValues(alpha: 0.5) // Hard shadow cutout
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.02
          ..strokeCap = StrokeCap.round,
      );
    }

    // --- 4. Floating Bobbins (Rivets) ---
    final int numBobbins = 10;
    for (int i = 0; i < numBobbins; i++) {
      final angle = (i * pi * 2) / numBobbins;
      final bobbinPos = Offset(
        center.dx + cos(angle) * carrierOuterRadius,
        center.dy + sin(angle) * carrierOuterRadius,
      );
      // Outer washer ring (bright steel pushing over carrier)
      canvas.drawCircle(
        bobbinPos,
        radius * 0.03,
        Paint()
          ..color = brightRotorColor
          ..style = PaintingStyle.fill,
      );
      // Inner washer ring (dark shadow layer inside bobbin)
      canvas.drawCircle(
        bobbinPos,
        radius * 0.018,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill,
      );
      // Hollow center pin
      canvas.drawCircle(
        bobbinPos,
        radius * 0.008,
        Paint()
          ..color = tireColor
          ..style = PaintingStyle.fill,
      );
    }

    // --- 5. Axle Hub ---
    // Carrier mounting flange
    canvas.drawCircle(
      center,
      carrierInnerRadius - radius * 0.03,
      Paint()
        ..color = hubColor
        ..style = PaintingStyle.fill,
    );
    // Dark deep cavity
    canvas.drawCircle(
      center,
      radius * 0.09,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );

    // Front fork axle nut (Large Hexagon Structure)
    final hexRadius = radius * 0.06;
    final Path hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * pi * 2) / 6 - pi / 2; // Point up
      final px = center.dx + cos(angle) * hexRadius;
      final py = center.dy + sin(angle) * hexRadius;
      if (i == 0) {
        hexPath.moveTo(px, py);
      } else {
        hexPath.lineTo(px, py);
      }
    }
    hexPath.close();
    canvas.drawPath(
      hexPath,
      Paint()
        ..color = brightRotorColor
        ..style = PaintingStyle.fill,
    );

    // Axle hollow bore
    canvas.drawCircle(
      center,
      radius * 0.03,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant BikeWheelPainter oldDelegate) {
    return oldDelegate.tireColor != tireColor ||
        oldDelegate.rimColor != rimColor ||
        oldDelegate.spokeColor != spokeColor ||
        oldDelegate.hubColor != hubColor;
  }
}
