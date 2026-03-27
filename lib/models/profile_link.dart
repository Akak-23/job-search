import 'package:flutter/material.dart';

/// Model for a social/profile link
class ProfileLink {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController urlController = TextEditingController();

  void dispose() {
    labelController.dispose();
    urlController.dispose();
  }

  Map<String, dynamic> toJson() => {
        'label': labelController.text,
        'url': urlController.text,
      };

  static ProfileLink fromJson(Map<String, dynamic> json) {
    final link = ProfileLink();
    link.labelController.text = json['label'] ?? '';
    link.urlController.text = json['url'] ?? '';
    return link;
  }
}
