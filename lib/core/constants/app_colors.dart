import 'package:flutter/material.dart';

/// Tirigo uygulamasının tüm renk sabitleri
/// DRY prensibi: Renkler tek bir yerden yönetilir, her yerde tekrar yazılmaz.
class AppColors {
  AppColors._(); // Instantiate edilemez

  // --- ANA MARKA RENKLERİ ---
  static const Color primary = Color(0xFF1B263B);     // Lacivert
  static const Color secondary = Color(0xFFF3722C);   // Turuncu

  // --- ARKA PLAN RENKLERİ ---
  static const Color background = Color(0xFFF4F4F4);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundCard = Colors.white;
  static const Color splashBackground = Color(0xFFF0F4F8);

  // --- METİN RENKLERİ ---
  static const Color textPrimary = Color(0xFF1B263B);
  static const Color textSecondary = Colors.blueGrey;
  static const Color textHint = Colors.grey;
  static const Color textWhite = Colors.white;
  static const Color textWhiteLight = Colors.white70;

  // --- DURUM RENKLERİ ---
  static const Color success = Colors.green;
  static const Color error = Colors.redAccent;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // --- İLAN DURUM RENKLERİ ---
  static const Color statusOpen = Colors.green;
  static const Color statusOnTheWay = Colors.blue;
  static const Color statusClosed = Colors.grey;

  // --- GÖLGE & BORDER ---
  static const Color shadow = Color(0x0D000000);      // %5 siyah
  static const Color divider = Color(0xFFF0F4F8);
  static const Color border = Color(0x1A000000);      // %10 siyah

  // --- OVERLAY RENKLERİ ---
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) =>
      secondary.withValues(alpha: opacity);
}