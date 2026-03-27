import 'package:flutter/material.dart';

class CoverLetterData {
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController coverLetterController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController requirementsController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController jobDescriptionController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  
  String selectedProvider = 'basic'; // Default to basic AI
  String apiKey = '';
  String customInstructions = '';
  
  // Data from resume profile (auto-populated)
  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  List<String> skills = [];
  List<Map<String, dynamic>> workExperience = []; // {title, company, description, period}
  List<Map<String, dynamic>> education = []; // {degree, institution, description, period}

  String get recipient => recipientController.text;
  String get company => companyController.text;
  String get jobTitle => jobTitleController.text;
  String get body => bodyController.text;

  void dispose() {
    recipientController.dispose();
    coverLetterController.dispose();
    jobTitleController.dispose();
    companyController.dispose();
    requirementsController.dispose();
    experienceController.dispose();
    jobDescriptionController.dispose();
    bodyController.dispose();
  }
}
