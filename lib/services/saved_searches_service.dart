import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_search.dart';

class SavedSearchesService {
  static const String _keyPrefix = 'saved_search_';
  static const String _listKey = 'saved_searches_list';

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

  /// Get all saved searches
  static Future<List<SavedSearch>> getSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_listKey) ?? [];

    final searches = <SavedSearch>[];
    for (final name in names) {
      final json = prefs.getString('$_keyPrefix$name');
      if (json != null) {
        try {
          searches.add(SavedSearch.fromJson(json));
        } catch (e) {
          // Skip corrupted entries but log for debugging
          // ignore: avoid_print
          print('Error loading saved search $name: $e');
          continue;
        }
      }
    }
    // ignore: avoid_print
    print('Loaded ${searches.length} saved searches');
    // Sort alphabetically by name
    searches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return searches;
  }

  /// Save a new search or update existing one
  static Future<void> saveSearch(SavedSearch search) async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_listKey) ?? [];

    // Check for an existing search with identical filters
    SavedSearch? duplicate;
    for (final name in names) {
      final json = prefs.getString('$_keyPrefix$name');
      if (json == null) continue;
      try {
        final existing = SavedSearch.fromJson(json);
        if (_filtersEqual(existing, search)) {
          duplicate = existing;
          break;
        }
      } catch (_) {
        // skip corrupted entries
        continue;
      }
    }

    if (duplicate != null) {
      // Promote existing match to the top and update its savedAt
      // Use notification state from the new search, not the duplicate
      final updated = SavedSearch(
        name: duplicate.name,
        was: duplicate.was,
        wo: duplicate.wo,
        berufsfeld: duplicate.berufsfeld,
        arbeitgeber: duplicate.arbeitgeber,
        veroeffentlichtseit: duplicate.veroeffentlichtseit,
        zeitarbeit: duplicate.zeitarbeit,
        angebotsart: duplicate.angebotsart,
        befristung: duplicate.befristung,
        arbeitszeit: duplicate.arbeitszeit,
        umkreis: duplicate.umkreis,
        savedAt: DateTime.now(),
        isDefault: duplicate.isDefault,
        notificationsEnabled: search.notificationsEnabled,
        lastResultCount: search.lastResultCount,
      );
      // Save updated duplicate
      await prefs.setString('$_keyPrefix${updated.name}', updated.toJson());
      return; // Do not create another entry
    }

    // Add name to list if not already present
    if (!names.contains(search.name)) {
      names.add(search.name);
      await prefs.setStringList(_listKey, names);
    }

    // Save the search data
    final toStore = SavedSearch(
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
      isDefault: search.isDefault,
      notificationsEnabled: search.notificationsEnabled,
      lastResultCount: search.lastResultCount,
    );
    await prefs.setString('$_keyPrefix${search.name}', toStore.toJson());
  }

  /// Delete a saved search by name
  static Future<void> deleteSearch(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_listKey) ?? [];

    // Remove from list
    names.remove(name);
    await prefs.setStringList(_listKey, names);

    // Remove the data
    await prefs.remove('$_keyPrefix$name');
  }

  /// Get a specific saved search by name
  static Future<SavedSearch?> getSearchByName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_keyPrefix$name');
    if (json != null) {
      try {
        return SavedSearch.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Rename a saved search
  static Future<void> renameSearch(String oldName, String newName) async {
    final search = await getSearchByName(oldName);
    if (search != null) {
      await deleteSearch(oldName);
      final updatedSearch = SavedSearch(
        name: newName,
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
        isDefault: search.isDefault,
        notificationsEnabled: search.notificationsEnabled,
        lastResultCount: search.lastResultCount,
      );
      await saveSearch(updatedSearch);
    }
  }

  /// Auto-save current search as last used
  static Future<void> autoSaveLastSearch(SavedSearch search) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSearchData = SavedSearch(
      name: '__last_search__',
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
    await prefs.setString('_auto_saved_search', lastSearchData.toJson());
  }

  /// Get the last auto-saved search
  static Future<SavedSearch?> getLastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('_auto_saved_search');
    if (json != null) {
      try {
        return SavedSearch.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Set a search as default (used on app startup)
  static Future<void> setDefaultSearch(String name) async {
    final search = await getSearchByName(name);
    if (search != null) {
      await deleteSearch(name);
      final updatedSearch = SavedSearch(
        name: name,
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
        isDefault: true,
        notificationsEnabled: search.notificationsEnabled,
        lastResultCount: search.lastResultCount,
      );
      await saveSearch(updatedSearch);
    }
  }

  /// Get the default search (used on app startup)
  static Future<SavedSearch?> getDefaultSearch() async {
    final searches = await getSavedSearches();
    try {
      return searches.firstWhere((s) => s.isDefault);
    } catch (e) {
      return null;
    }
  }

  /// Clear the default search
  static Future<void> clearDefaultSearch() async {
    final searches = await getSavedSearches();
    for (final search in searches) {
      if (search.isDefault) {
        await deleteSearch(search.name);
        final updatedSearch = SavedSearch(
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
          savedAt: search.savedAt,
          isDefault: false,
          notificationsEnabled: search.notificationsEnabled,
          lastResultCount: search.lastResultCount,
        );
        await saveSearch(updatedSearch);
      }
    }
  }

  /// Get all searches sorted by save date (newest first)
  static Future<List<SavedSearch>> getSavedSearchesSortedByDate() async {
    final searches = await getSavedSearches();
    searches.sort((a, b) {
      final dateA = a.savedAt ?? DateTime(1970);
      final dateB = b.savedAt ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return searches;
  }

  /// Check if auto-save is enabled (by checking if last search exists)
  static Future<bool> hasAutoSavedSearch() async {
    final lastSearch = await getLastSearch();
    return lastSearch != null;
  }

  /// Get quick access to recently saved searches
  static Future<List<SavedSearch>> getRecentSearches({int limit = 5}) async {
    final searches = await getSavedSearchesSortedByDate();
    return searches.take(limit).toList();
  }

  /// Update an existing saved search with new parameters
  static Future<void> updateSearch(
    String name, {
    String? was,
    String? wo,
    String? berufsfeld,
    String? arbeitgeber,
    String? veroeffentlichtseit,
    bool? zeitarbeit,
    String? angebotsart,
    String? befristung,
    String? arbeitszeit,
    double? umkreis,
    bool? notificationsEnabled,
    int? lastResultCount,
  }) async {
    // ignore: avoid_print
    print('Updating search: $name with notificationsEnabled=$notificationsEnabled');
    final search = await getSearchByName(name);
    if (search == null) {
      // ignore: avoid_print
      print('Search $name not found');
      return;
    }

    final updatedSearch = SavedSearch(
      name: name,
      was: was ?? search.was,
      wo: wo ?? search.wo,
      berufsfeld: berufsfeld ?? search.berufsfeld,
      arbeitgeber: arbeitgeber ?? search.arbeitgeber,
      veroeffentlichtseit: veroeffentlichtseit ?? search.veroeffentlichtseit,
      zeitarbeit: zeitarbeit ?? search.zeitarbeit,
      angebotsart: angebotsart ?? search.angebotsart,
      befristung: befristung ?? search.befristung,
      arbeitszeit: arbeitszeit ?? search.arbeitszeit,
      umkreis: umkreis ?? search.umkreis,
      savedAt: DateTime.now(),
      isDefault: search.isDefault,
      notificationsEnabled: notificationsEnabled ?? search.notificationsEnabled,
      lastResultCount: lastResultCount ?? search.lastResultCount,
    );
    // ignore: avoid_print
    print('Updated search notificationsEnabled=${updatedSearch.notificationsEnabled}');
    await saveSearch(updatedSearch);
    // ignore: avoid_print
    print('Save complete');
  }
}
