import 'package:flutter/material.dart';

/// Canary Duress Lock — Cyber-Stealth Minimalist Dark Theme
/// Primary palette anchored in obsidian #090A0F with neon shield accents
class AppTheme {
  // ── Core Colors ──
  static const obsidian = Color(0xFF090A0F);
  static const obsidianLight = Color(0xFF13151E);
  static const obsidianPanel = Color(0xFF1A1D2B);
  static const obsidianCard = Color(0xFF1E2235);
  static const obsidianBorder = Color(0xFF2A2F4A);

  static const neonGreen = Color(0xFF10B981);
  static const neonGreenDim = Color(0xFF0D9468);
  static const neonGreenGlow = Color(0x3310B981);
  static const emeraldPulse = Color(0xFF34D399);

  static const dangerRed = Color(0xFFEF4444);
  static const warningAmber = Color(0xFFF59E0B);
  static const infoBlue = Color(0xFF3B82F6);

  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const textGhost = Color(0xFF475569);

  // ── Decoy Mode Colors (benign / warm) ──
  static const decoyBg = Color(0xFFF8FAFC);
  static const decoyPanel = Color(0xFFFFFFFF);
  static const decoyText = Color(0xFF1E293B);
  static const decoyAccent = Color(0xFF6366F1);
  static const decoyMuted = Color(0xFF94A3B8);

  static ThemeData get darkStealthTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        onPrimary: obsidian,
        secondary: emeraldPulse,
        surface: obsidianPanel,
        onSurface: textPrimary,
        error: dangerRed,
        outline: obsidianBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: obsidian,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: obsidianLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: obsidianBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: obsidianBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: obsidian,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: obsidianBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: neonGreen),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return obsidian;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonGreen;
          return obsidianPanel;
        }),
      ),
      dividerTheme: const DividerThemeData(color: obsidianBorder, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: obsidianPanel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: neonGreen, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    );
  }

  static ThemeData get decoyLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: decoyBg,
      colorScheme: const ColorScheme.light(
        primary: decoyAccent,
        onPrimary: Colors.white,
        surface: decoyPanel,
        onSurface: decoyText,
        outline: Color(0xFFE2E8F0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: decoyPanel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: decoyText, fontSize: 17, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: decoyText),
      ),
    );
  }
}

/// Glow container for stealth accents
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = AppTheme.neonGreen,
    this.borderRadius = 16,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.obsidianPanel,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: glowColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: glowColor.withOpacity(0.08), blurRadius: 20, spreadRadius: 1),
          BoxShadow(color: glowColor.withOpacity(0.04), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: child,
    );
  }
}

/// Pulsing status indicator
class PulseIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final String label;

  const PulseIndicator({super.key, required this.color, this.size = 10, required this.label});

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_anim.value),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 8)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(widget.label,
            style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ],
    );
  }
}
