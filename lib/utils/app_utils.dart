import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility functions for common operations
/// This class should not be instantiated
class AppUtils {
  // Prevent instantiation
  AppUtils._();

  // Regular expressions
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _phoneRegex = RegExp(r'^[\d\s()+-]{7,}$');
  static final _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Copies text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Shows a floating snackbar with optional action
  static void showSnackBar(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an error dialog with a dismiss button
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(actionLabel ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Formats a date string to DD.MM.YYYY format
  /// Returns 'Date unknown' if the date cannot be parsed
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date unknown';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  /// Validates if a string is a valid email address
  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  /// Validates if a string is a valid phone number
  /// Must be at least 7 characters with digits, spaces, parentheses, +, or -
  static bool isValidPhoneNumber(String phone) {
    return _phoneRegex.hasMatch(phone);
  }

  /// Truncates a string to a maximum length with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Delays execution for the specified duration
  static Future<void> delay({
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await Future.delayed(duration);
  }

  /// Checks if text contains special characters
  static bool containsSpecialCharacters(String text) {
    return _specialCharRegex.hasMatch(text);
  }

  /// Converts a string to title case (e.g., "hello world" -> "Hello World")
  static String toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) => _capitalizeWord(word))
        .join(' ');
  }

  /// Capitalizes the first letter of a word and lowercases the rest
  static String _capitalizeWord(String word) {
    if (word.isEmpty) return '';
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  /// Extracts initials from a name (max 2 letters)
  /// e.g., "John Doe" -> "JD", "Jane" -> "J"
  static String getInitials(String name) {
    return name
        .split(' ')
        .take(2)
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
        .join();
  }
}
