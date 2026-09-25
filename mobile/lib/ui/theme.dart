// Shared Music Room design system: an "after-hours radio" aesthetic with a
// deep forest canvas and one sharp chartreuse accent.
//
// Font choice (stated before implementation per AGENTS.md): Montserrat for
// expressive display/body typography + JetBrains Mono for ranks, versions,
// timestamps, and player timecodes. No system-font-only screens.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const accent = Color(0xFFA7F26B);
  static const accentDeep = Color(0xFF5EA83C);

  static const ink = Color(0xFF07100B);
  static const bgDark = Color(0xFF09110D);
  static const surfaceDark = Color(0xFF101A15);
  static const surfaceRaisedDark = Color(0xFF17241D);
  static const fieldDark = Color(0xFF1A2821);
  static const borderDark = Color(0xFF2B3A32);
  static const textDark = Color(0xFFF2F7F3);
  static const textMutedDark = Color(0xFFB8C6BD);

  static const paper = Color(0xFFF5F7F2);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedLight = Color(0xFFE9EFE7);
  static const fieldLight = Color(0xFFEBF0E9);
  static const borderLight = Color(0xFFCAD5CA);
  static const textLight = Color(0xFF132018);
  static const textMutedLight = Color(0xFF53635A);

  static const danger = Color(0xFFFFB4AB);
  static const success = Color(0xFF72D89A);
  static const warning = Color(0xFFFFD180);
}

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static double page(double width) {
    if (width >= 1200) return 32;
    if (width >= 700) return 24;
    return 16;
  }

  static double maxContentWidth(double width) {
    if (width >= 1500) return 1240;
    return 1120;
  }
}

class AppRadii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double pill = 999;
}

class AppDurations {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const reveal = Duration(milliseconds: 420);
}

class AppTheme {
  // Light accent/error as compile-time constants so border sides can be const.
  static const _lightPrimary = Color(0xFF397A25);
  static const _lightError = Color(0xFFBA1A1A);

  static TextTheme _textTheme(
    TextTheme base,
    Color primaryText,
    Color secondaryText,
  ) {
    final text = GoogleFonts.montserratTextTheme(base);
    return text.copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 44,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
        color: primaryText,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 36,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: primaryText,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 30,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primaryText,
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 28,
        height: 1.16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: primaryText,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primaryText,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primaryText,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: primaryText,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: primaryText,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: secondaryText,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: secondaryText,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 10.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: secondaryText,
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.ink,
      secondary: Color(0xFF8FD9B0),
      onSecondary: AppColors.ink,
      error: AppColors.danger,
      onError: Color(0xFF690005),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDark,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: AppColors.borderDark),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      canvasColor: AppColors.bgDark,
      textTheme: _textTheme(
        base.textTheme,
        AppColors.textDark,
        AppColors.textMutedDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaisedDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldDark,
        hintStyle: const TextStyle(color: AppColors.textMutedDark),
        labelStyle: const TextStyle(color: AppColors.textMutedDark),
        helperStyle: const TextStyle(color: AppColors.textMutedDark),
        prefixIconColor: AppColors.textMutedDark,
        suffixIconColor: AppColors.textMutedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border,
        enabledBorder: border,
        disabledBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.fieldDark,
          disabledForegroundColor: AppColors.textMutedDark,
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.fieldDark,
          disabledForegroundColor: AppColors.textMutedDark,
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.borderDark),
          disabledForegroundColor: AppColors.textMutedDark,
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(48, 44),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textMutedDark,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.ink,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 3,
        shape: StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.textMutedDark,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.montserrat(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.textDark
                : AppColors.textMutedDark,
          );
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.accent,
        selectedIconTheme: IconThemeData(color: AppColors.ink),
        unselectedIconTheme: IconThemeData(color: AppColors.textMutedDark),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textMutedDark,
          fontWeight: FontWeight.w500,
        ),
        useIndicator: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: AppColors.borderDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: AppColors.textMutedDark,
        textColor: AppColors.textDark,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.textMutedDark,
        collapsedIconColor: AppColors.textMutedDark,
        textColor: AppColors.textDark,
        collapsedTextColor: AppColors.textDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaisedDark,
        contentTextStyle: GoogleFonts.montserrat(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.borderDark,
        thumbColor: AppColors.accent,
        overlayColor: const Color(0x33A7F26B),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.borderDark,
        circularTrackColor: AppColors.borderDark,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaisedDark,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.borderDark),
        ),
        textStyle: GoogleFonts.montserrat(
          color: AppColors.textDark,
          fontSize: 12,
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: Color(0xFF397A25),
      onPrimary: Colors.white,
      secondary: Color(0xFF386A57),
      onSecondary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textLight,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: AppColors.borderLight),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      textTheme: _textTheme(
        base.textTheme,
        AppColors.textLight,
        AppColors.textMutedLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        modalBackgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldLight,
        hintStyle: const TextStyle(color: AppColors.textMutedLight),
        labelStyle: const TextStyle(color: AppColors.textMutedLight),
        helperStyle: const TextStyle(color: AppColors.textMutedLight),
        prefixIconColor: AppColors.textMutedLight,
        suffixIconColor: AppColors.textMutedLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: _lightPrimary, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: _lightError),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: _lightError, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: AppColors.textLight,
          side: const BorderSide(color: AppColors.borderLight),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 44),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textMutedLight,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.surfaceRaisedLight,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.surfaceRaisedLight,
        selectedIconTheme: IconThemeData(color: AppColors.textLight),
        unselectedIconTheme: IconThemeData(color: AppColors.textMutedLight),
      ),
      dividerColor: AppColors.borderLight,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textLight,
        contentTextStyle: GoogleFonts.montserrat(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: AppColors.borderLight,
        thumbColor: scheme.primary,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}