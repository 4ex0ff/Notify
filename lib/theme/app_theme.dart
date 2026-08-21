import 'package:flutter/material.dart';
import 'app_theme_variables.dart';

abstract class AppTheme {
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // --- Заголовки ---

      // H1: Самый большой заголовок (для названий документов, разделов)
      headlineLarge: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w700, // Bold
        letterSpacing: -0.5,
        height: 1.2,
        color: colorScheme.onSurface,
      ),

      // H2: Средний заголовок (подзаголовки первого уровня, крупные блоки)
      headlineMedium: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600, // Semi-Bold
        letterSpacing: -0.2,
        height: 1.25,
        color: colorScheme.onSurface,
      ),

      // H3: Малый заголовок (заголовки карточек, групп в сайдбаре)
      headlineSmall: TextStyle(
        fontSize: 15.0,
        fontWeight: FontWeight.w600, // Semi-Bold
        height: 1.3,
        color: colorScheme.onSurface,
      ),

      // --- Основной и дополнительный тексты ---

      // Основной текст (для редактора заметок, чтения)
      bodyLarge: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400, // Regular
        height: 1.45,
        color: colorScheme.onSurface,
      ),

      // Дополнительный текст (для списков файлов, тултипов, элементов интерфейса)
      bodyMedium: TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: colorScheme.onSurface,
      ),

      // Мелкий текст (для дат, статусов, подписей в сайдбаре)
      bodySmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: colorScheme.onSurfaceVariant, // Чуть менее контрастный цвет
      ),

      // --- Вспомогательный текст ---

      // Вспомогательный текст (приглушенный, близкий к фону: подсказки, плейсхолдеры)
      labelSmall: TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: colorScheme.outline, // Используем цвет контура/плейсхолдера
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 84, 116, 151), // Акцентный цвет
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1E1E1E), // Фон редактора
          surfaceContainerLowest: const Color(0xFF141414), // Фон сайдбара
          surfaceContainerHigh: const Color(
            0xFF2B2B2B,
          ), // Фон инпутов и ховеров
          surfaceContainerHighest: const Color(
            0xFF383838,
          ), // Фон выбранного элемента
          // Текстовые цвета
          onSurface: const Color(0xFFE0E0E0), // Основной текст
          onSurfaceVariant: const Color.fromARGB(
            255,
            177,
            177,
            177,
          ), // Второстепенный текст
          outline: const Color(0xFF606060), // Приглушённый текст / Разделители
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),

      // Скаффолд и общие фоны
      scaffoldBackgroundColor: colorScheme.surface,

      // Автоматическая стилизация глобальных компонентов
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppThemeVariables.iconMd,
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.surfaceContainerHigh;
            }
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.16);
            }
            return null;
          }),
        ),
      ),
    );
  }
}

extension TypographyContext on BuildContext {
  // Быстрый доступ к текстовым стилям темы
  TextTheme get typography => Theme.of(this).textTheme;

  // Алиасы
  TextStyle? get h1 => typography.headlineLarge;
  TextStyle? get h2 => typography.headlineMedium;
  TextStyle? get h3 => typography.headlineSmall;

  TextStyle? get body => typography.bodyLarge;
  TextStyle? get bodySecondary => typography.bodyMedium;
  TextStyle? get bodySmall => typography.bodySmall;

  TextStyle? get muted => typography.labelSmall;
}

extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
}
