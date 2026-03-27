import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import '../services/applications_service.dart';

/// Provider for managing applications state with proper error handling
class ApplicationsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _applications = [];
  bool isLoading = false;
  String? error;
  String filterStage = filterAll;

  List<Map<String, dynamic>> get applications => _applications;

  List<Map<String, dynamic>> get filteredApplications {
    if (filterStage == filterAll) return _applications;
    return _applications.where((app) => app['stage'] == filterStage).toList();
  }

  /// Gets the count of all applications
  int get applicationCount => _applications.length;

  /// Gets the count of filtered applications
  int get filteredCount => filteredApplications.length;

  /// Loads applications from storage with proper error handling
  Future<void> loadApplications() async {
    _setLoadingState(true);
    try {
      final loaded = await ApplicationsService.loadApplications();
      _applications = loaded;
      _clearError();
    } catch (err) {
      _setError(err.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  /// Adds a new application
  /// Notifies listeners only if successful
  Future<void> addApplication(Map<String, dynamic> application) async {
    try {
      _applications.add(application);
      await ApplicationsService.saveApplications(_applications);
      _clearError();
      notifyListeners();
    } catch (err) {
      // Revert on failure
      _applications.removeLast();
      _setError(err.toString());
      notifyListeners();
    }
  }

  /// Updates an application at the given index
  /// Returns false if index is invalid
  Future<bool> updateApplication(
    int index,
    Map<String, dynamic> application,
  ) async {
    if (!_isValidIndex(index)) {
      _setError('Invalid application index');
      return false;
    }

    final previous = _applications[index];
    try {
      _applications[index] = application;
      await ApplicationsService.saveApplications(_applications);
      _clearError();
      notifyListeners();
      return true;
    } catch (err) {
      // Revert on failure
      _applications[index] = previous;
      _setError(err.toString());
      notifyListeners();
      return false;
    }
  }

  /// Deletes an application at the given index
  /// Returns false if index is invalid
  /// Also unfavorites the job when deleting
  Future<bool> deleteApplication(int index) async {
    if (!_isValidIndex(index)) {
      _setError('Invalid application index');
      return false;
    }

    final removed = _applications.removeAt(index);
    try {
      await ApplicationsService.saveApplications(_applications);

      // Also remove from saved jobs (favorites) if it exists
      final jobMap = Map<String, String>.from(
        removed.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      );
      await ApplicationsService.removeSavedJob(jobMap);
      // Force UI updates listening to favorites even if nothing was removed
      ApplicationsService.savedJobsVersion.value++;

      _clearError();
      notifyListeners();
      return true;
    } catch (err) {
      // Revert on failure
      _applications.insert(index, removed);
      _setError(err.toString());
      notifyListeners();
      return false;
    }
  }

  /// Sets the filter stage and notifies listeners
  void setFilterStage(String stage) {
    if (filterStage != stage) {
      filterStage = stage;
      notifyListeners();
    }
  }

  /// Validates if an index is within bounds
  bool _isValidIndex(int index) => index >= 0 && index < _applications.length;

  /// Updates loading state and notifies listeners
  void _setLoadingState(bool value) {
    if (isLoading != value) {
      isLoading = value;
      notifyListeners();
    }
  }

  /// Sets error message
  void _setError(String message) {
    error = message;
  }

  /// Clears error message
  void _clearError() {
    error = null;
  }

  /// Clears all state
  void clear() {
    _applications = [];
    isLoading = false;
    error = null;
    filterStage = filterAll;
    notifyListeners();
  }
}
