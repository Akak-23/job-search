import 'package:flutter/foundation.dart';
import '../services/applications_service.dart';

/// Provider for managing favorites state
class FavoritesProvider extends ChangeNotifier {
  List<Map<String, String>> _favorites = [];
  bool isLoading = false;
  String? error;

  List<Map<String, String>> get favorites => _favorites;

  /// Load favorites
  Future<void> loadFavorites() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _syncFavoritesFromStorage();
      error = null;
    } catch (err) {
      error = err.toString();
      _favorites = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Add favorite
  Future<void> addFavorite(Map<String, String> job) async {
    if (_isFavorite(job)) return;

    try {
      await ApplicationsService.addSavedJob(job);
      await _syncFavoritesFromStorage();
      error = null;
    } catch (err) {
      error = err.toString();
    }
    notifyListeners();
  }

  /// Remove favorite
  Future<void> removeFavorite(Map<String, String> job) async {
    try {
      await ApplicationsService.removeSavedJob(job);
      await _syncFavoritesFromStorage();
      error = null;
    } catch (err) {
      error = err.toString();
    }
    notifyListeners();
  }

  /// Toggle favorite
  Future<void> toggleFavorite(Map<String, String> job) async {
    if (_isFavorite(job)) {
      await removeFavorite(job);
    } else {
      await addFavorite(job);
    }
  }

  /// Check if job is favorite
  bool _isFavorite(Map<String, String> job) {
    return _favorites.any((j) => _sameJob(j, job));
  }

  /// Check if job is favorited by reference
  bool isFavorited(String? jobId) {
    if (jobId == null) return false;
    return _favorites.any((j) => j['refnr'] == jobId);
  }

  /// Get favorite count
  int get favoriteCount => _favorites.length;

  /// Check if favorites are empty
  bool get isEmpty => _favorites.isEmpty;

  bool _sameJob(Map<String, String> a, Map<String, String> b) {
    final refA = a['refnr'];
    final refB = b['refnr'];
    if (refA != null && refA.isNotEmpty && refB != null && refB.isNotEmpty) {
      return refA == refB;
    }
    return a['title'] == b['title'] && a['description'] == b['description'];
  }

  Future<void> _syncFavoritesFromStorage() async {
    final saved = await ApplicationsService.getSavedApplications();
    _favorites = saved
        .map((app) => app.map((k, v) => MapEntry(k, v?.toString() ?? '')))
        .toList();
  }
}
