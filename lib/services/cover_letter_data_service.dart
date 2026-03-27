import 'package:shared_preferences/shared_preferences.dart';
import '../models/cover_letter_data.dart';

/// Service for persisting cover letter data
class CoverLetterDataService {
  static const _recipientKey = 'coverLetterRecipient';
  static const _companyKey = 'coverLetterCompany';
  static const _jobTitleKey = 'coverLetterJobTitle';
  static const _bodyKey = 'coverLetterBody';

  static Future<CoverLetterData> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = CoverLetterData();

    data.recipientController.text = prefs.getString(_recipientKey) ?? '';
    data.companyController.text = prefs.getString(_companyKey) ?? '';
    data.jobTitleController.text = prefs.getString(_jobTitleKey) ?? '';
    data.bodyController.text = prefs.getString(_bodyKey) ?? '';

    return data;
  }

  static Future<void> saveData(CoverLetterData data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_recipientKey, data.recipientController.text);
    await prefs.setString(_companyKey, data.companyController.text);
    await prefs.setString(_jobTitleKey, data.jobTitleController.text);
    await prefs.setString(_bodyKey, data.bodyController.text);
  }
}
