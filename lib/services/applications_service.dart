import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_strings.dart';
import '../services/cover_letter_data_service.dart';

/// Service for managing job applications persistence
class ApplicationsService {
  /// Notifies listeners when saved jobs (favorites) change
  static final ValueNotifier<int> savedJobsVersion = ValueNotifier<int>(0);
  static const String _storageKey = 'applications';

  /// Validates if an index is within bounds
  static bool _isValidIndex(int index, int length) =>
      index >= 0 && index < length;

  /// Normalizes any value to a string
  static String _stringValue(dynamic value) => value?.toString() ?? '';

  /// Checks if a stored application matches the provided job map
  static bool _jobsMatch(
    Map<String, dynamic> application,
    Map<String, String> job,
  ) {
    final appRef = _stringValue(application['refnr']);
    final jobRef = _stringValue(job['refnr']);
    if (appRef.isNotEmpty && jobRef.isNotEmpty) {
      return appRef == jobRef;
    }

    return _stringValue(application['title']) == _stringValue(job['title']) &&
        _stringValue(application['description']) ==
            _stringValue(job['description']);
  }

  /// Saves applications to local storage
  static Future<void> saveApplications(
    List<Map<String, dynamic>> applications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(applications);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Loads applications from local storage
  /// Returns empty list if no data or on parse error
  static Future<List<Map<String, dynamic>>> loadApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Adds a new application for a job
  static Future<void> addApplication(
    Map<String, String> job, {
    String stage = stageSaved,
  }) async {
    final applications = await loadApplications();
    if (_findApplicationIndex(applications, job) != -1) return;

    applications.add(await _buildApplicationEntry(job, stage));
    await saveApplications(applications);
  }

  /// Updates an application at the given index
  /// Silently fails if index is out of bounds
  static Future<void> updateApplication(
    int index,
    Map<String, dynamic> application,
  ) async {
    final applications = await loadApplications();
    if (!_isValidIndex(index, applications.length)) return;

    applications[index] = application;
    await saveApplications(applications);
  }

  /// Deletes an application at the given index
  /// Silently fails if index is out of bounds
  static Future<void> deleteApplication(int index) async {
    final applications = await loadApplications();
    if (!_isValidIndex(index, applications.length)) return;

    applications.removeAt(index);
    await saveApplications(applications);
  }

  /// Clears all saved applications
  static Future<void> clearApplications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Gets all applications with 'Saved' stage
  static Future<List<Map<String, dynamic>>> getSavedApplications() async {
    final applications = await loadApplications();
    return applications.where((app) => app['stage'] == stageSaved).toList();
  }

  /// Adds a saved job without affecting other application stages
  static Future<void> addSavedJob(Map<String, String> job) async {
    final applications = await loadApplications();
    if (_findSavedApplicationIndex(applications, job) != -1) return;
    if (_findApplicationIndex(applications, job) != -1) return;

    applications.add(await _buildApplicationEntry(job, stageSaved));
    await saveApplications(applications);
    savedJobsVersion.value++;
  }

  /// Removes a saved job entry (stage: Saved)
  static Future<void> removeSavedJob(Map<String, String> job) async {
    final applications = await loadApplications();
    final savedIndex = _findSavedApplicationIndex(applications, job);
    if (!_isValidIndex(savedIndex, applications.length)) return;

    applications.removeAt(savedIndex);
    await saveApplications(applications);
    savedJobsVersion.value++;
  }

  /// Toggles saved status for a job without deleting active applications
  static Future<void> toggleSaved(Map<String, String> job) async {
    final applications = await loadApplications();
    final savedIndex = _findSavedApplicationIndex(applications, job);
    if (_isValidIndex(savedIndex, applications.length)) {
      applications.removeAt(savedIndex);
      await saveApplications(applications);
      savedJobsVersion.value++;
      return;
    }

    if (_findApplicationIndex(applications, job) != -1) return;

    applications.add(await _buildApplicationEntry(job, stageSaved));
    await saveApplications(applications);
    savedJobsVersion.value++;
  }

  /// Checks if a job is saved
  static Future<bool> isSaved(Map<String, String> job) async {
    final applications = await loadApplications();
    return _findSavedApplicationIndex(applications, job) != -1;
  }

  /// Checks if a job has an active application (any stage)
  static Future<bool> isApplied(Map<String, String> job) async {
    final applications = await loadApplications();
    return _findApplicationIndex(applications, job) != -1;
  }

  /// Finds the index of an application matching the job
  /// Returns -1 if not found
  static int _findApplicationIndex(
    List<Map<String, dynamic>> applications,
    Map<String, String> job,
  ) {
    return applications.indexWhere((app) => _jobsMatch(app, job));
  }

  /// Finds the index of a saved (stage: Saved) application matching the job
  static int _findSavedApplicationIndex(
    List<Map<String, dynamic>> applications,
    Map<String, String> job,
  ) {
    return applications.indexWhere(
      (app) => app['stage'] == stageSaved && _jobsMatch(app, job),
    );
  }

  /// Loads cover letter data for a new application
  static Future<Map<String, dynamic>?> _loadCoverLetterData() async {
    try {
      final coverLetter = await CoverLetterDataService.loadData();
      if (_isCoverLetterEmpty(coverLetter)) {
        return null;
      }
      return _coverLetterToJson(coverLetter);
    } catch (_) {
      return null;
    }
  }

  /// Checks if cover letter has any content
  static bool _isCoverLetterEmpty(dynamic coverLetter) {
    return coverLetter.recipient.isEmpty &&
        coverLetter.company.isEmpty &&
        coverLetter.jobTitle.isEmpty &&
        coverLetter.body.isEmpty;
  }

  /// Converts cover letter to JSON map with timestamp
  static Map<String, dynamic> _coverLetterToJson(dynamic coverLetter) {
    return {
      'recipient': coverLetter.recipient,
      'company': coverLetter.company,
      'jobTitle': coverLetter.jobTitle,
      'body': coverLetter.body,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Updates cover letter for an existing application
  static Future<void> updateApplicationCoverLetter(
    int index,
    Map<String, dynamic> coverLetterData,
  ) async {
    final applications = await loadApplications();
    if (!_isValidIndex(index, applications.length)) return;

    final app = applications[index];
    app['coverLetter'] = {
      ...coverLetterData,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await saveApplications(applications);
  }

  /// Builds a standard application entry
  static Future<Map<String, dynamic>> _buildApplicationEntry(
    Map<String, String> job,
    String stage,
  ) async {
    return {
      ...job,
      'stage': stage,
      'notes': [],
      'documents': [],
      'createdAt': DateTime.now().toIso8601String(),
      'coverLetter': await _loadCoverLetterData(),
    };
  }
}
