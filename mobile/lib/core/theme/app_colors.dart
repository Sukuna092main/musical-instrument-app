import 'package:flutter/material.dart';

/// Brand colors cố định, không đổi giữa light/dark mode.
/// Screens dùng Theme.of(context) cho surface/text; chỉ dùng các màu này
/// cho accent (xanh lá), badge (vàng), và lỗi (đỏ).
class AppColors {
  AppColors._();

  static const accent = Color(0xFF1F7A5A); // primary green
  static const accentDark = Color(0xFF163B32); // dark green card/badge
  static const accentSurface = Color(0xFFE8EFE7); // light green tint surface

  static const gold = Color(0xFFFFD700);
  static const goldText = Color(0xFFB7791F);

  static const error = Color(0xFFB42318);
  static const errorSurface = Color(0xFFFEE4E2);

  static const lockBg = Color(0xFFFFF4DE);

  static const offWhite = Color(0xFFF7F7F2); // scaffold fallback light
}
