import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_search.dart';
import 'dart:convert';

/// Service for managing search history and auto-save functionality
class SearchHistoryService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryItems = 20;

  /// Compare two searches by their filter fields (ignoring name, savedAt, isDefault)
  static bool _filtersEqual(SavedSearch a, SavedSearch b) {
    bool strEq(String x, String y) => (x.trim() == y.trim());
    bool doubleClose(double x, double y) => (x - y).abs() < 0.0001;

    List<String> splitSort(String v) {
      return v
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList()
        ..sort();
    }

    final arbeitszeitA = splitSort(a.arbeitszeit);
    final arbeitszeitB = splitSort(b.arbeitszeit);
    final angebotsartA = splitSort(a.angebotsart);
    final angebotsartB = splitSort(b.angebotsart);

    return strEq(a.was, b.was) &&
      strEq(a.wo, b.wo) &&
      strEq(a.berufsfeld, b.berufsfeld) &&
      strEq(a.arbeitgeber, b.arbeitgeber) &&
      strEq(a.veroeffentlichtseit, b.veroeffentlichtseit) &&
        a.zeitarbeit == b.zeitarbeit &&
      strEq(a.befristung, b.befristung) &&
        _listEquals(arbeitszeitA, arbeitszeitB) &&
        _listEquals(angebotsartA, angebotsartB) &&
      doubleClose(a.umkreis, b.umkreis);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Add search to history
  static Future<void> addToHistory(SavedSearch search) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';

    try {
      final history = jsonDecode(historyJson) as List;
      
      // Check if an identical search already exists
      int duplicateIndex = -1;
      for (int i = 0; i < history.length; i++) {
        try {
          final existing = SavedSearch.fromMap(history[i]);
          if (_filtersEqual(existing, search)) {
            duplicateIndex = i;
            break;
          }
        } catch (_) {
          // Skip corrupted entries
          continue;
        }
      }

      // If duplicate exists, remove it (will be re-added at the top)
      if (duplicateIndex >= 0) {
        history.removeAt(duplicateIndex);
      }

      // Create entry with timestamp for chronological ordering
      final entry = SavedSearch(
        name: search.name,
        was: search.was,
        wo: search.wo,
        berufsfeld: search.berufsfeld,
        arbeitgeber: search.arbeitgeber,
        veroeffentlichtseit: search.veroeffentlichtseit,
        zeitarbeit: search.zeitarbeit,
        angebotsart: search.angebotsart,
        befristung: search.befristung,
        arbeitszeit: search.arbeitszeit,
        umkreis: search.umkreis,
        savedAt: DateTime.now(),
        isDefault: false,
      );

      // Add new search at the beginning (newest first)
      history.insert(0, jsonDecode(entry.toJson()));

      // Keep only the last 20 searches
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      // Reset history if corrupted
      await prefs.setString(_historyKey, jsonEncode([]));
    }
  }

  /// Get search history
  static Future<List<SavedSearch>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';

    try {
      final raw = jsonDecode(historyJson) as List;
      final history = raw.map((item) => SavedSearch.fromMap(item)).toList();

      // Ensure chronological order (newest first) using savedAt
      history.sort((a, b) {
        final at = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return history;
    } catch (e) {
      return [];
    }
  }

  /// Clear search history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode([]));
  }

  /// Remove specific items by name (legacy; removes all matches)
  static Future<void> removeFromHistory(String searchName) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';

    try {
      final history = jsonDecode(historyJson) as List;
      history.removeWhere((item) => item['name'] == searchName);
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      // Ignore errors
    }
  }

  /// Remove a single item from history by index
  static Future<void> removeFromHistoryAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';

    try {
      final history = jsonDecode(historyJson) as List;
      if (index >= 0 && index < history.length) {
        history.removeAt(index);
        await prefs.setString(_historyKey, jsonEncode(history));
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get the most frequently used search parameters
  static Future<SavedSearch?> getMostUsedSearchPattern() async {
    final history = await getHistory();
    if (history.isEmpty) return null;

    // Count occurrences of each search pattern
    final patterns = <String, int>{};
    for (final search in history) {
      final pattern = '${search.was}|${search.wo}|${search.berufsfeld}';
      patterns[pattern] = (patterns[pattern] ?? 0) + 1;
    }

    // Find the most used pattern
    String? mostUsedPattern;
    int maxCount = 0;
    patterns.forEach((pattern, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsedPattern = pattern;
      }
    });

    // Return the first search with this pattern
    if (mostUsedPattern != null) {
      return history.firstWhere(
        (s) => '${s.was}|${s.wo}|${s.berufsfeld}' == mostUsedPattern,
      );
    }
    return null;
  }
}
