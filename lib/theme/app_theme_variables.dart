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

  /*
  // Отступы в EdgeInsets
  static const EdgeInsets paddingXXs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXl = EdgeInsets.all(xxl);

  // Отступы в SizedBox
  static const Widget gapXXs = SizedBox(width: xxs, height: xxs);
  static const Widget gapXs = SizedBox(width: xs, height: xs);
  static const Widget gapSm = SizedBox(width: sm, height: sm);
  static const Widget gapMd = SizedBox(width: md, height: md);
  static const Widget gapLg = SizedBox(width: lg, height: lg);
  static const Widget gapXl = SizedBox(width: xl, height: xl);
  static const Widget gapXXl = SizedBox(width: xxl, height: xxl);
  */

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
