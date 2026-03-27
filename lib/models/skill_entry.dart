import 'package:flutter/material.dart';

/// Model for a skill entry with optional certificate
class SkillEntry {
  late final TextEditingController nameController;
  String? certificatePath;

  SkillEntry() {
    nameController = TextEditingController();
  }

  /// Disposes the name controller
  void dispose() {
    nameController.dispose();
  }

  /// Converts the entry to JSON
  Map<String, dynamic> toJson() => {
        'name': nameController.text,
        'certificatePath': certificatePath,
      };

  /// Creates a SkillEntry from JSON
  /// Properly initializes the controller with loaded data
  static SkillEntry fromJson(Map<String, dynamic> json) {
    final entry = SkillEntry();
    entry.nameController.text = json['name'] ?? '';
    entry.certificatePath = json['certificatePath'] as String?;
    return entry;
  }
}
