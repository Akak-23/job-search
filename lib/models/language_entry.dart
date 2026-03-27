import 'package:flutter/material.dart';

/// Model for a language entry with level and optional certificate
class LanguageEntry {
  late final TextEditingController nameController;
  String? level; // A1, A2, B1, B2, C1, C2, Native
  String? certificatePath;

  LanguageEntry() {
    nameController = TextEditingController();
  }

  /// Disposes the name controller
  void dispose() {
    nameController.dispose();
  }

  /// Converts the entry to JSON
  Map<String, dynamic> toJson() => {
        'name': nameController.text,
        'level': level,
        'certificatePath': certificatePath,
      };

  /// Creates a LanguageEntry from JSON
  /// Properly initializes the controller with loaded data
  static LanguageEntry fromJson(Map<String, dynamic> json) {
    final entry = LanguageEntry();
    entry.nameController.text = json['name'] ?? '';
    entry.level = json['level'] as String?;
    entry.certificatePath = json['certificatePath'] as String?;
    return entry;
  }
}
