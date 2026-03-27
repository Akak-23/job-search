import 'package:flutter/foundation.dart';
import '../models/resume_data.dart';
import '../services/resume_data_service.dart';

/// Provider for managing resume state
class ResumeProvider extends ChangeNotifier {
  late ResumeData _personalData;
  bool isLoading = false;
  String? error;

  ResumeProvider() {
    _personalData = ResumeData();
  }

  ResumeData get personalData => _personalData;

  /// Load resume data
  Future<void> loadResumeData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await ResumeDataService.loadPersonalData();
      _personalData = data;
      error = null;
    } catch (err) {
      error = err.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Save resume data
  Future<void> saveResumeData() async {
    try {
      await ResumeDataService.savePersonalData(_personalData);
      error = null;
    } catch (err) {
      error = err.toString();
    }
    notifyListeners();
  }

  /// Update personal field
  void updatePersonalField(String field, String value) {
    // Note: ResumeData uses TextEditingControllers
    // This method is kept for potential future use
    // Direct controller updates are preferred
    notifyListeners();
  }

  /// Dispose
  @override
  void dispose() {
    _personalData.dispose();
    super.dispose();
  }
}
