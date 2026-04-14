import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rider_app/common/sizes.dart';
import 'package:rider_app/common/styles/spacing_styles.dart';
import 'package:rider_app/common/text.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

import 'package:rider_app/ui/film_grain_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool isDarkMode = true;
  late final AnimationController _bgController;
  Offset _center = const Offset(0, 0);
  Offset _velocity = const Offset(0.3, 0.2);
  double _prevT = 0;
  final Random _rand = Random();
  // configurable bounds for Alignment space (-bounds..+bounds)
  final double _bounds = 1.0; // try 0.8 for tighter, 1.2 for looser
  late StreamSubscription<AccelerometerEvent> _accelSub;
  double _ax = 0;
  double _ay = 0;
  Color get bgColor => isDarkMode ? Colors.black : Colors.white;
  Color get primaryText => isDarkMode ? Colors.white : Colors.black;
  Color get secondaryText => isDarkMode ? Colors.white70 : Colors.black54;
  Color get borderColor => isDarkMode ? Colors.white12 : Colors.black12;
  Color get fieldFill => isDarkMode ? Colors.black : Colors.white;
  Color get glowColor => isDarkMode ? Colors.yellow : Colors.cyan;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final angle = _rand.nextDouble() * 2 * pi;
    _velocity = Offset(cos(angle), sin(angle)) * 0.8;

    _accelSub = accelerometerEventStream().listen((event) {
      // Smooth the raw accelerometer values
      _ax = _ax * 0.8 + event.x * 0.2;
      _ay = _ay * 0.8 + event.y * 0.2;

      // Apply as a gentle additive force, not a velocity override
      final dx = -_ax;
      final dy = _ay;

      _velocity = Offset(_velocity.dx + dx * 0.004, _velocity.dy + dy * 0.004);
    });

    emailFocus.addListener(() {
      setState(() {});
    });

    passwordFocus.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _accelSub.cancel();
    _bgController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FilmGrainOverlay(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  final t = _bgController.value;

                  double dt = t - _prevT;
                  if (dt < 0) dt += 1;
                  _prevT = t;

                  _velocity *= 0.999;
                  _center += _velocity * dt * 2;

                  const restitution = 0.85;

                  if (_center.dx > _bounds) {
                    _center = Offset(_bounds, _center.dy);
                    _velocity = Offset(
                      -_velocity.dx.abs() * restitution,
                      _velocity.dy,
                    );
                  } else if (_center.dx < -_bounds) {
                    _center = Offset(-_bounds, _center.dy);
                    _velocity = Offset(
                      _velocity.dx.abs() * restitution,
                      _velocity.dy,
                    );
                  }

                  if (_center.dy > _bounds) {
                    _center = Offset(_center.dx, _bounds);
                    _velocity = Offset(
                      _velocity.dx,
                      -_velocity.dy.abs() * restitution,
                    );
                  } else if (_center.dy < -_bounds) {
                    _center = Offset(_center.dx, -_bounds);
                    _velocity = Offset(
                      _velocity.dx,
                      _velocity.dy.abs() * restitution,
                    );
                  }

                  const minSpeed = 0.45;
                  final speed = _velocity.distance;
                  if (speed < minSpeed) {
                    final dir = speed > 0
                        ? _velocity / speed
                        : const Offset(1, 0);
                    _velocity = dir * minSpeed;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(_center.dx, _center.dy),
                        radius: 1,
                        colors: isDarkMode
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
              ),
            ),
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: TSpacingStyles.paddingWithAppBarHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KEEP YOUR EXISTING UI HERE (no changes needed)
                      const SizedBox(height: TSizes.spaceBtwSections),

                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: primaryText,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              isDarkMode = !isDarkMode;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Logo Text
                      Text(
                        TTexts.loginTitle,
                        style: GoogleFonts.moiraiOne(
                          fontWeight: FontWeight.bold,
                          fontSize: 72,
                          color: primaryText,
                          shadows: [
                            Shadow(
                              blurRadius: 100,
                              color: Colors.white.withAlpha(80),
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 20,
                              color: Colors.white.withAlpha(60),
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections + 20),

                      // Email Field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        transformAlignment: Alignment.center,
                        transform: emailFocus.hasFocus
                            ? (Matrix4.identity()
                                ..scaleByDouble(1.01, 1.01, 1.0, 1.0))
                            : Matrix4.identity(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: emailFocus.hasFocus
                              ? [
                                  BoxShadow(
                                    color: glowColor.withAlpha(120),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: TextFormField(
                          focusNode: emailFocus,
                          controller: emailController,
                          style: TextStyle(color: primaryText),
                          onTap: () {
                            HapticFeedback.selectionClick();
                          },
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: TextStyle(color: secondaryText),
                            filled: true,
                            fillColor: fieldFill,
                            prefixIcon: Icon(Icons.email, color: secondaryText),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: glowColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      // Password Field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        transformAlignment: Alignment.center,
                        transform: passwordFocus.hasFocus
                            ? (Matrix4.identity()
                                ..scaleByDouble(1.01, 1.01, 1.0, 1.0))
                            : Matrix4.identity(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: passwordFocus.hasFocus
                              ? [
                                  BoxShadow(
                                    color: glowColor.withAlpha(120),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: TextFormField(
                          focusNode: passwordFocus,
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: primaryText),
                          onTap: () {
                            HapticFeedback.selectionClick();
                          },
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: secondaryText),
                            filled: true,
                            fillColor: fieldFill,
                            prefixIcon: Icon(Icons.lock, color: secondaryText),
                            suffixIcon: passwordController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: secondaryText,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: glowColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      Builder(
                        builder: (context) {
                          final isPressed = ValueNotifier<bool>(false);

                          return ValueListenableBuilder<bool>(
                            valueListenable: isPressed,
                            builder: (context, value, child) {
                              return GestureDetector(
                                onTapDown: (_) => isPressed.value = true,
                                onTapUp: (_) => isPressed.value = false,
                                onTapCancel: () => isPressed.value = false,
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  isPressed.value = true;
                                  await Future.delayed(
                                    const Duration(milliseconds: 80),
                                  );
                                  isPressed.value = false;
                                },
                                child: AnimatedScale(
                                  scale: value ? 0.97 : 1.0,
                                  duration: const Duration(milliseconds: 100),
                                  curve: Curves.easeInOut,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: value
                                            ? (isDarkMode
                                                  ? Colors.grey[200]
                                                  : Colors.grey[700])
                                            : (isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              if (emailController
                                                      .text
                                                      .isEmpty ||
                                                  passwordController
                                                      .text
                                                      .isEmpty) {
                                                HapticFeedback.heavyImpact();
                                                Overlay.of(context).insert(
                                                  OverlayEntry(
                                                    builder: (context) =>
                                                        _AnimatedAlert(
                                                          message:
                                                              "Enter email and password",
                                                        ),
                                                  ),
                                                );
                                                return;
                                              }

                                              setState(() => isLoading = true);

                                              await Future.delayed(
                                                const Duration(seconds: 1),
                                              ); // placeholder for Firebase auth

                                              if (!mounted) return;

                                              setState(() => isLoading = false);

                                              //Navigator.pushReplacement(
                                              //context,
                                              //MaterialPageRoute(
                                              //builder: (context) => const GridScreen(),
                                              //),
                                              //);
                                            },
                                      child: isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                            )
                                          : Text(
                                              "Sign in",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(color: secondaryText),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      // Sign Up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: secondaryText),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: primaryText,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      Center(
                        child: Text(
                          "or",
                          style: TextStyle(color: secondaryText),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      // Social Icons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _socialIcon(Icons.g_mobiledata),
                          _socialIcon(Icons.facebook),
                          _socialIcon(Icons.apple),
                          _socialIconAsset('assets/icons/github.png'),
                        ],
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems + 54),

                      // Signature
                      Center(
                        child: Text(
                          TTexts.signatureTitle,
                          style: GoogleFonts.bitcountPropSingle(
                            fontSize: 12,
                            color: secondaryText.withAlpha(80),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('$icon pressed');
        },
        splashColor: Colors.white10,
        highlightColor: Colors.white10,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        child: Container(
          padding: const EdgeInsets.all(TSizes.iconSm + 2),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withAlpha(120)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            border: Border.all(color: borderColor),
          ),
          child: icon == Icons.g_mobiledata
              ? Image.asset(
                  'assets/icons/google.png',
                  height: TSizes.iconMd,
                  width: TSizes.iconMd,
                )
              : Icon(icon, color: secondaryText, size: TSizes.iconMd),
        ),
      ),
    );
  }

  Widget _socialIconAsset(String assetPath) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('$assetPath pressed');
        },
        splashColor: Colors.white10,
        highlightColor: Colors.white10,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        child: Container(
          padding: const EdgeInsets.all(TSizes.iconSm + 2),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withAlpha(120)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Image.asset(
            assetPath,
            height: TSizes.iconMd,
            width: TSizes.iconMd,
          ),
        ),
      ),
    );
  }
}

// Custom animated bottom alert widget
class _AnimatedAlert extends StatefulWidget {
  final String message;

  const _AnimatedAlert({required this.message});

  @override
  State<_AnimatedAlert> createState() => _AnimatedAlertState();
}

class _AnimatedAlertState extends State<_AnimatedAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slide = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      await _controller.reverse();
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 12),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
