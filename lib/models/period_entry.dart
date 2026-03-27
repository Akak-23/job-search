import 'package:flutter/material.dart';

/// Model for a period entry (work experience or education)
class PeriodEntry {
  late final TextEditingController titleController;
  late final TextEditingController companyController;
  String? startMonth;
  late final TextEditingController startYearController;
  String? endMonth;
  late final TextEditingController endYearController;
  bool isPresent = false;
  String? pdfPath;
  late final TextEditingController bulletsController;
  List<String> bulletPoints = [];

  PeriodEntry() {
    titleController = TextEditingController();
    companyController = TextEditingController();
    startYearController = TextEditingController();
    endYearController = TextEditingController();
    bulletsController = TextEditingController();
  }

  /// Disposes all text editing controllers
  void dispose() {
    titleController.dispose();
    companyController.dispose();
    startYearController.dispose();
    endYearController.dispose();
    bulletsController.dispose();
  }

  /// Converts the entry to JSON
  Map<String, dynamic> toJson() => {
        'title': titleController.text,
        'company': companyController.text,
        'startMonth': startMonth,
        'startYear': startYearController.text,
        'endMonth': endMonth,
        'endYear': endYearController.text,
        'isPresent': isPresent,
        'pdfPath': pdfPath,
        'bullets': bulletPoints,
      };

  /// Creates a PeriodEntry from JSON
  /// Properly initializes all controllers with loaded data
  static PeriodEntry fromJson(Map<String, dynamic> json) {
    final entry = PeriodEntry();
    entry.titleController.text = json['title'] ?? '';
    entry.companyController.text = json['company'] ?? '';
    entry.startMonth = json['startMonth'] as String?;
    entry.startYearController.text = json['startYear'] ?? '';
    entry.endMonth = json['endMonth'] as String?;
    entry.endYearController.text = json['endYear'] ?? '';
    entry.isPresent = json['isPresent'] as bool? ?? false;
    entry.pdfPath = json['pdfPath'] as String?;
    
    final bullets = json['bullets'];
    if (bullets is List) {
      entry.bulletPoints = bullets.whereType<String>().toList();
    }
    entry.bulletsController.text = entry.bulletPoints.join('\n');
    
    return entry;
  }
}
