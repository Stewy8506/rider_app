import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rider_app/common/sizes.dart';
import 'package:weather_icons/weather_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isDarkMode = true;

  Color get primaryText => isDarkMode ? Colors.white : Colors.black;
  Color get secondaryText => isDarkMode ? Colors.grey : Colors.black54;
  Color get cardColor =>
      isDarkMode ? const Color(0xFF1A1A1C) : Colors.grey[200]!;
  Color get surfaceColor => isDarkMode ? Colors.black : Colors.white;

  Color getRideColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.yellow;
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }

  int rideScore = 8; // Example score, replace with actual logic

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0E0E10) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu),
                    color: primaryText,
                    onPressed: () {},
                  ),

                  const SizedBox(width: TSizes.md),

                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "MotoCircle",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.bitcountPropSingle(
                          color: primaryText,
                          letterSpacing: 2,
                          fontSize: TSizes.fontXl,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: primaryText,
                    ),
                    onPressed: () {
                      setState(() {
                        isDarkMode = !isDarkMode;
                      });
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: TSizes.md,
                    right: TSizes.md,
                  ),
                  child: Column(
                    children: [
                      //Weather Card
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(WeatherIcons.day_sunny),
                            ),

                            const SizedBox(width: TSizes.md),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Howrah, WB",
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w500,
                                      fontSize: TSizes.fontSm,
                                      color: primaryText,
                                    ),
                                  ),

                                  const SizedBox(height: TSizes.sm),
                                  // Rain + Visibility Row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.thermostat,
                                        size: TSizes.md,
                                        color: secondaryText,
                                      ),

                                      const SizedBox(width: TSizes.xs),

                                      Text(
                                        "36°C",
                                        style: GoogleFonts.montserrat(
                                          color: secondaryText,
                                        ),
                                      ),

                                      const SizedBox(width: TSizes.md),

                                      Icon(
                                        WeatherIcons.raindrop,
                                        size: TSizes.md,
                                        color: secondaryText,
                                      ),
                                      const SizedBox(width: TSizes.xs),
                                      Text(
                                        "10%",
                                        style: TextStyle(color: secondaryText),
                                      ),
                                      const SizedBox(width: TSizes.md),
                                      Icon(
                                        Icons.remove_red_eye,
                                        size: TSizes.md,
                                        color: secondaryText,
                                      ),
                                      const SizedBox(width: TSizes.xs + 2),
                                      Text(
                                        "8 km",
                                        style: TextStyle(color: secondaryText),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: TSizes.sm),
                                ],
                              ),
                            ),

                            // Ride score circle + label
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDarkMode ? const Color(0xFF0E0E10) : Colors.white,
                                    border: Border.all(
                                      color: getRideColor(rideScore),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: getRideColor(rideScore).withAlpha(60),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Transform.translate(
                                      offset: const Offset(2, 1),
                                      child: Text(
                                        rideScore.toString(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.bitcountPropSingle(
                                          color: primaryText,
                                          fontSize: TSizes.fontXl,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "Confidence",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: secondaryText,
                                    fontSize: TSizes.fontXs,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      //TODO: Map Card

                      // Music Card
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isDarkMode ? Colors.white : Colors.black)
                                  .withAlpha(30),

                              blurRadius: 20,

                              spreadRadius: 1,

                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: TSizes.xs),

                            Text(
                              "NOW PLAYING",
                              style: GoogleFonts.bitcountPropSingle(
                                color: isDarkMode
                                    ? Colors.black87
                                    : Colors.white70,
                                fontSize: TSizes.fontXs,
                                letterSpacing: 2,
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Track name
                                Expanded(
                                  child: Text(
                                    "Get Lucky - Daft Punk",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Controls
                                Row(
                                  children: [
                                    Icon(
                                      Icons.skip_previous,
                                      color: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      size: 22,
                                    ),

                                    const SizedBox(width: 10),

                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      child: Icon(
                                        Icons.pause,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        size: 22,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Icon(
                                      Icons.skip_next,
                                      color: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: 0.2,
                                minHeight: 4,
                                color: Colors.blueAccent,
                                backgroundColor: isDarkMode
                                    ? Colors.grey
                                    : Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Group Session
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "GROUP SESSION",
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 2,
                                        color: secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Midnight Run [4/6]",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(40),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Connected",
                                        style: GoogleFonts.bitcountPropSingle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: TSizes.fontSm,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            _userTile("Kenji_88", "0.4 KM ahead"),

                            _userTile("Sarah_Moto", "Trailing 1.2 KM"),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.volume_off,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: TSizes.defaultSpace),

                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.mic_off,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Nav
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: cardColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.map, color: primaryText),
                  ),
                  Icon(Icons.group, color: secondaryText),
                  Icon(Icons.play_circle, color: secondaryText),
                  Icon(Icons.bar_chart, color: secondaryText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userTile(String name, String status) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: primaryText, fontWeight: FontWeight.w500),
            ),
          ),
          Text(status, style: TextStyle(color: secondaryText)),
        ],
      ),
    );
  }
}
