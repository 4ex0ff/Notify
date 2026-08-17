import 'package:flutter/material.dart';

abstract class AppThemeVariables {
  // Базовые отступы
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Скругления
  static final BorderRadius borderRadiusXs = BorderRadius.circular(4.0);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(8.0);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(12.0);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(16.0);

  // Размеры иконок
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
}
