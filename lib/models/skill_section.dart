import 'package:flutter/material.dart';
import 'skill_entry.dart';

/// Model for a skill section containing multiple skills
class SkillSection {
  final TextEditingController titleController = TextEditingController();
  final List<SkillEntry> skills = [];

  void dispose() {
    titleController.dispose();
    for (final skill in skills) {
      skill.dispose();
    }
  }

  Map<String, dynamic> toJson() => {
        'title': titleController.text,
        'skills': skills.map((s) => s.toJson()).toList(),
      };

  static SkillSection fromJson(Map<String, dynamic> json) {
    final section = SkillSection();
    section.titleController.text = json['title'] ?? '';
    final skillsList = json['skills'];
    if (skillsList is List) {
      section.skills
          .addAll(skillsList.map((item) => SkillEntry.fromJson(item)));
    }
    return section;
  }
}
