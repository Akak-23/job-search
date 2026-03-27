import 'package:flutter/material.dart';

/// Centralized color definitions for the application
/// This class should not be instantiated
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0x00e5e7eb);

  // Secondary Colors
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0x00f3e8ff);

  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFEDC2D);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDefault = Color(0xFFCBD5E1);
  static const Color borderDark = Color(0xFF94A3B8);

  // Utility Colors
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadowColor = Color(0x1F000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Stage Colors
  static const Map<String, Color> stageColors = {
    'Saved': Color(0xFF3B82F6),
    'Applied': Color(0xFF8B5CF6),
    'Interview': Color(0xFFF59E0B),
    'Offer': Color(0xFF10B981),
    'Rejected': Color(0xFFEF4444),
  };

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
