import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rider_app/common/sizes.dart';
import 'package:rider_app/common/styles/spacing_styles.dart';
import 'package:rider_app/common/text.dart';
import 'package:rider_app/ui/film_grain_overlay.dart';
import 'package:rider_app/ui/physics_ball_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool isDarkMode = true;

  Color get primaryText => isDarkMode ? Colors.white : Colors.black;
  Color get secondaryText => isDarkMode ? Colors.white70 : Colors.black54;
  Color get borderColor => isDarkMode ? Colors.white12 : Colors.black12;
  Color get fieldFill => isDarkMode ? Colors.black : Colors.white;
  Color get glowColor => isDarkMode ? Colors.yellow : Colors.cyan;

  @override
  void initState() {
    super.initState();
    nameFocus.addListener(() => setState(() {}));
    emailFocus.addListener(() => setState(() {}));
    passwordFocus.addListener(() => setState(() {}));
    confirmPasswordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  Widget _buildField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focus,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: focus.hasFocus
          ? (Matrix4.identity()..scale(1.01))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: focus.hasFocus
            ? [
                BoxShadow(
                  color: glowColor.withAlpha(120),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focus,
        obscureText: obscure,
        style: TextStyle(color: primaryText),
        onTap: () => HapticFeedback.selectionClick(),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: secondaryText),
          filled: true,
          fillColor: fieldFill,
          prefixIcon: Icon(icon, color: secondaryText),
          suffixIcon: toggle != null && controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: secondaryText,
                  ),
                  onPressed: toggle,
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
            borderSide: BorderSide(color: glowColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: PhysicsBallBackground(isDarkMode: isDarkMode),
          ),
          FilmGrainOverlay(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: TSpacingStyles.paddingWithAppBarHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: TSizes.spaceBtwSections),

                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: primaryText,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => isDarkMode = !isDarkMode);
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Sign Up",
                        style: GoogleFonts.moiraiOne(
                          fontWeight: FontWeight.bold,
                          fontSize: 72,
                          color: primaryText,
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections + 20),

                      _buildField(
                        hint: "Full Name",
                        icon: Icons.person,
                        controller: nameController,
                        focus: nameFocus,
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      _buildField(
                        hint: "Email",
                        icon: Icons.email,
                        controller: emailController,
                        focus: emailFocus,
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      _buildField(
                        hint: "Password",
                        icon: Icons.lock,
                        controller: passwordController,
                        focus: passwordFocus,
                        obscure: _obscurePassword,
                        toggle: () {
                          setState(() =>
                              _obscurePassword = !_obscurePassword);
                        },
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      _buildField(
                        hint: "Confirm Password",
                        icon: Icons.lock,
                        controller: confirmPasswordController,
                        focus: confirmPasswordFocus,
                        obscure: _obscureConfirm,
                        toggle: () {
                          setState(() =>
                              _obscureConfirm = !_obscureConfirm);
                        },
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.white
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (passwordController.text !=
                                      confirmPasswordController.text) {
                                    HapticFeedback.heavyImpact();
                                    return;
                                  }

                                  setState(() => isLoading = true);
                                  await Future.delayed(
                                      const Duration(seconds: 1));
                                  setState(() => isLoading = false);
                                },
                          child: isLoading
                              ? CircularProgressIndicator(
                                  color: isDarkMode
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : Text(
                                  "Create Account",
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: secondaryText),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: primaryText,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems + 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}