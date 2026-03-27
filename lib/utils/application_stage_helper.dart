import 'dart:ui';
import '../constants/app_strings.dart';

/// Helper class for application stage colors and utilities
/// This class should not be instantiated
class ApplicationStageHelper {
  // Prevent instantiation
  ApplicationStageHelper._();

  static const List<String> stages = [
    stageSaved,
    'Preparing',
    'Application Sent',
    'Follow-up Phone Call',
    stageInterview,
    'Negotiations',
    'Accepted',
    'Declined',
  ];

  // Color constants for consistency
  static const Color _brightBlue = Color(0xFF2196F3);
  static const Color _cyan = Color(0xFF00BCD4);
  static const Color _brightOrange = Color(0xFFFF9800);
  static const Color _brightPurple = Color(0xFF9C27B0);
  static const Color _brightGreen = Color(0xFF4CAF50);
  static const Color _brightAmber = Color(0xFFFFC107);
  static const Color _lightGreen = Color(0xFF66BB6A);
  static const Color _brightRed = Color(0xFFE57373);
  static const Color _grey = Color(0xFF9E9E9E);

  /// Returns the color associated with a given stage
  /// Returns grey if the stage is not recognized
  static Color getStageColor(String stage) {
    return switch (stage) {
      stageSaved => _brightBlue,
      'Preparing' => _cyan,
      'Application Sent' => _brightOrange,
      'Follow-up Phone Call' => _brightPurple,
      stageInterview => _brightGreen,
      'Negotiations' => _brightAmber,
      'Accepted' => _lightGreen,
      'Declined' => _brightRed,
      _ => _grey,
    };
  }

  /// Checks if notes should be displayed for a given stage
  /// Currently always returns true - can be extended for stage-specific logic
  static bool shouldShowNotes(String stage) => true;
}
