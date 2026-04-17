import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hebrew_date_service.dart';
import '../services/widget_service.dart';
import '../widgets/day_counter_display.dart';
import '../widgets/info_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  final bool isHebrew;

  const HomeScreen({
    super.key,
    required this.onToggleLocale,
    required this.isHebrew,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    // Update widget data when app opens
    WidgetService.updateWidget();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = HebrewDateService.durationSinceChurban();
    final isThreeWeeks = HebrewDateService.isInThreeWeeks();
    final isNineDays = HebrewDateService.isInNineDays();
    final isTishaBAv = HebrewDateService.isTodayTishaBAv();
    final hebrewDate = HebrewDateService.getTodayHebrewFormatted();
    final isHeb = widget.isHebrew;

    // Special theme during mourning periods
    final Color primaryColor =
        isTishaBAv
            ? const Color(0xFF1A1A1A)
            : isNineDays
                ? const Color(0xFF2C1810)
                : isThreeWeeks
                    ? const Color(0xFF3D2914)
                    : const Color(0xFF1B3A4B);

    final Color accentColor =
        isTishaBAv
            ? const Color(0xFF666666)
            : isNineDays
                ? const Color(0xFFB8860B)
                : const Color(0xFFD4A84B);

    return Directionality(
      textDirection: isHeb ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.85),
                const Color(0xFF0A0A0A),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  // Top bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Language toggle
                          GestureDetector(
                            onTap: widget.onToggleLocale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isHeb ? 'EN' : 'עב',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Hebrew date
                          Text(
                            hebrewDate,
                            style: GoogleFonts.frankRuhlLibre(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(
                        children: [
                          Text(
                            isHeb ? 'זכר לחורבן' : 'Zecher LaChurban',
                            style: GoogleFonts.frankRuhlLibre(
                              color: accentColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHeb
                                ? 'מספר הימים מאז חורבן בית המקדש'
                                : 'Days since the destruction of the Beit HaMikdash',
                            style: GoogleFonts.assistant(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main counter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: DayCounterDisplay(
                        totalDays: duration.totalDays,
                        accentColor: accentColor,
                        isHebrew: isHeb,
                      ),
                    ),
                  ),

                  // Duration breakdown
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDurationUnit(
                            value: duration.years.toString(),
                            label: isHeb ? 'שנים' : 'Years',
                            accentColor: accentColor,
                          ),
                          _buildDivider(accentColor),
                          _buildDurationUnit(
                            value: duration.months.toString(),
                            label: isHeb ? 'חודשים' : 'Months',
                            accentColor: accentColor,
                          ),
                          _buildDivider(accentColor),
                          _buildDurationUnit(
                            value: duration.days.toString(),
                            label: isHeb ? 'ימים' : 'Days',
                            accentColor: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),

                  // Info cards
                  if (isTishaBAv)
                    SliverToBoxAdapter(
                      child: InfoCard(
                        icon: Icons.warning_amber_rounded,
                        title: isHeb ? 'היום ט\' באב' : 'Today is Tisha B\'Av',
                        subtitle: isHeb
                            ? 'יום צום לזכר חורבן בית המקדש'
                            : 'Fast day commemorating the destruction',
                        color: Colors.red.shade400,
                        isHebrew: isHeb,
                      ),
                    ),

                  if (isThreeWeeks && !isTishaBAv)
                    SliverToBoxAdapter(
                      child: InfoCard(
                        icon: Icons.access_time,
                        title: isHeb ? 'בין המצרים' : 'The Three Weeks',
                        subtitle: isHeb
                            ? 'תקופת אבלות על חורבן בית המקדש'
                            : 'Period of mourning for the Temple\'s destruction',
                        color: accentColor,
                        isHebrew: isHeb,
                      ),
                    ),

                  // Pasuk
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
                      child: Text(
                        isHeb
                            ? '״אִם אֶשְׁכָּחֵךְ יְרוּשָׁלָ‌ִם\nתִּשְׁכַּח יְמִינִי״'
                            : '"If I forget you, O Jerusalem,\nlet my right hand forget its skill"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.frankRuhlLibre(
                          color: accentColor.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.8,
                        ),
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

  Widget _buildDurationUnit({
    required String value,
    required String label,
    required Color accentColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.assistant(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.assistant(
            color: accentColor.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      height: 40,
      width: 1,
      color: color.withValues(alpha: 0.2),
    );
  }
}
