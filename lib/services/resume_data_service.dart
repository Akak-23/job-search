import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/period_entry.dart';
import '../models/skill_section.dart';
import '../models/language_entry.dart';
import '../models/profile_link.dart';
import '../models/resume_data.dart';

/// Service for managing resume data persistence
class ResumeDataService {
  static const List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> languageLevels = [
    'Native',
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];

  /// Load personal data from shared preferences
  static Future<ResumeData> loadPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = ResumeData();

    data.firstNameController.text = prefs.getString('firstName') ?? '';
    data.birthDateController.text = prefs.getString('birthDate') ?? '';
    data.birthPlaceController.text = prefs.getString('birthPlace') ?? '';
    data.streetController.text = prefs.getString('street') ?? '';
    data.houseNumberController.text = prefs.getString('houseNumber') ?? '';
    data.postalCodeController.text = prefs.getString('postalCode') ?? '';
    data.cityController.text = prefs.getString('city') ?? '';
    data.emailController.text = prefs.getString('email') ?? '';
    data.phoneController.text = prefs.getString('phone') ?? '';

    final imageBase64 = prefs.getString('profileImage');
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      data.profileImageBytes = base64Decode(imageBase64);
    }

    return data;
  }

  /// Save personal data to shared preferences
  static Future<void> savePersonalData(ResumeData data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('firstName', data.firstNameController.text);
    await prefs.setString('birthDate', data.birthDateController.text);
    await prefs.setString('birthPlace', data.birthPlaceController.text);
    await prefs.setString('street', data.streetController.text);
    await prefs.setString('houseNumber', data.houseNumberController.text);
    await prefs.setString('postalCode', data.postalCodeController.text);
    await prefs.setString('city', data.cityController.text);
    await prefs.setString('email', data.emailController.text);
    await prefs.setString('phone', data.phoneController.text);

    if (data.profileImageBytes != null) {
      await prefs.setString(
        'profileImage',
        base64Encode(data.profileImageBytes!),
      );
    } else {
      await prefs.remove('profileImage');
    }
  }

  /// Load work entries from shared preferences
  static Future<List<PeriodEntry>> loadWorkEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final workJson = prefs.getString('workEntries');

    if (workJson != null) {
      final List<dynamic> workList = jsonDecode(workJson);
      return workList.map((item) => PeriodEntry.fromJson(item)).toList();
    }

    return []; // Start with no entries by default
  }

  /// Save work entries to shared preferences
  static Future<void> saveWorkEntries(List<PeriodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final workJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('workEntries', workJson);
  }

  /// Load education entries from shared preferences
  static Future<List<PeriodEntry>> loadEducationEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final educationJson = prefs.getString('educationEntries');

    if (educationJson != null) {
      final List<dynamic> educationList = jsonDecode(educationJson);
      return educationList.map((item) => PeriodEntry.fromJson(item)).toList();
    }

    return []; // Start with no entries by default
  }

  /// Save education entries to shared preferences
  static Future<void> saveEducationEntries(List<PeriodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final educationJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('educationEntries', educationJson);
  }

  /// Load profile links from shared preferences
  static Future<List<ProfileLink>> loadProfileLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final linksJson = prefs.getString('profileLinks');

    if (linksJson != null) {
      final List<dynamic> linksList = jsonDecode(linksJson);
      return linksList.map((item) => ProfileLink.fromJson(item)).toList();
    }

    return []; // Return empty list
  }

  /// Save profile links to shared preferences
  static Future<void> saveProfileLinks(List<ProfileLink> links) async {
    final prefs = await SharedPreferences.getInstance();
    final linksJson = jsonEncode(links.map((l) => l.toJson()).toList());
    await prefs.setString('profileLinks', linksJson);
  }

  static Future<List<SkillSection>> loadSkillSections() async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = prefs.getString('skillSections');

    if (sectionsJson != null) {
      final List<dynamic> sectionsList = jsonDecode(sectionsJson);
      return sectionsList.map((item) => SkillSection.fromJson(item)).toList();
    }

    // No persisted data: start with no sections to avoid empty placeholders
    return [];
  }

  /// Save skill sections to shared preferences
  static Future<void> saveSkillSections(List<SkillSection> sections) async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = jsonEncode(sections.map((s) => s.toJson()).toList());
    await prefs.setString('skillSections', sectionsJson);
  }

  /// Load language entries from shared preferences
  static Future<List<LanguageEntry>> loadLanguageEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final languagesJson = prefs.getString('languageEntries');

    if (languagesJson != null) {
      final List<dynamic> languagesList = jsonDecode(languagesJson);
      return languagesList.map((item) => LanguageEntry.fromJson(item)).toList();
    }

    return []; // No persisted data: start with no entries
  }

  /// Save language entries to shared preferences
  static Future<void> saveLanguageEntries(List<LanguageEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final languagesJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('languageEntries', languagesJson);
  }

  /// Validate period entries
  static String? validatePeriodEntries(
    List<PeriodEntry> entries,
    String entryType,
  ) {
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final title = e.titleController.text.trim();

      if (title.isEmpty) continue; // Skip empty blocks

      if (e.startYearController.text.trim().isEmpty) {
        return '$entryType entry "$title" needs a start year';
      }

      if (int.tryParse(e.startYearController.text.trim()) == null) {
        return '$entryType entry "$title" has invalid start year';
      }

      if (!e.isPresent && e.endYearController.text.trim().isNotEmpty) {
        if (int.tryParse(e.endYearController.text.trim()) == null) {
          return '$entryType entry "$title" has invalid end year';
        }
      }
    }

    return null;
  }
}
