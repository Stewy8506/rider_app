import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FilmGrainOverlay extends StatefulWidget {
  final Widget child;
  final double opacity; // 0.03–0.09 is cinematic sweet spot
  final double grainSize; // 1.0 = fine, 2.0 = coarse
  final int fps; // real film grain flickers ~12–24fps

  const FilmGrainOverlay({
    super.key,
    required this.child,
    this.opacity = 0.02,
    this.grainSize = 1.8,
    this.fps = 12,
  });

  @override
  State<FilmGrainOverlay> createState() => _FilmGrainOverlayState();
}

class _FilmGrainOverlayState extends State<FilmGrainOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastFrame = Duration.zero;
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final interval = Duration(microseconds: (1000000 / widget.fps).round());
      if (elapsed - _lastFrame >= interval) {
        _lastFrame = elapsed;
        setState(() => _seed = elapsed.inMicroseconds);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            // taps pass through to UI below
            child: CustomPaint(
              painter: _GrainPainter(
                seed: _seed,
                opacity: widget.opacity,
                grainSize: widget.grainSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  final int seed;
  final double opacity;
  final double grainSize;

  _GrainPainter({
    required this.seed,
    required this.opacity,
    required this.grainSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(seed);
    final paint = Paint();
    final cols = (size.width / grainSize).ceil();
    final rows = (size.height / grainSize).ceil();

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final bright = rand.nextDouble();
        // Gaussian-ish: only render grain when value is near extremes
        // This avoids a flat grey mist and gives real grain speckle
        if (bright < 0.08 || bright > 0.92) {
          paint.color = (bright > 0.5 ? Colors.white : Colors.black)
              .withOpacity(
                opacity *
                    (bright > 0.5
                        ? (bright - 0.85) / 0.15
                        : (0.15 - bright) / 0.15),
              );
          canvas.drawRect(
            Rect.fromLTWH(x * grainSize, y * grainSize, grainSize, grainSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.seed != seed;
}
