import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_search_filters.dart';

/// Service for managing onboarding state and user filter preferences
class OnboardingService {
  static const _hasCompletedOnboardingKey = 'hasCompletedOnboarding';
  static const _firstRunAfterOnboardingKey = 'firstRunAfterOnboarding';
  static const _wasKey = 'onboarding_was';
  static const _woKey = 'onboarding_wo';
  static const _umkreisKey = 'onboarding_umkreis';
  static const _berufsfeldKey = 'onboarding_berufsfeld';
  static const _arbeitgeberKey = 'onboarding_arbeitgeber';
  static const _veroeffentlichtseitKey = 'onboarding_veroeffentlichtseit';
  static const _arbeitszeitKey = 'onboarding_arbeitszeit';
  static const _angebotsartKey = 'onboarding_angebotsart';
  static const _zeitarbeitKey = 'onboarding_zeitarbeit';

  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    // Mark that next app view should auto-search using onboarding filters
    await prefs.setBool(_firstRunAfterOnboardingKey, true);
  }

  /// Returns true if this is the first run right after onboarding,
  /// and resets the flag so it won't trigger on subsequent launches.
  static Future<bool> consumeFirstRunAfterOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(_firstRunAfterOnboardingKey) ?? false;
    if (isFirstRun) {
      await prefs.setBool(_firstRunAfterOnboardingKey, false);
    }
    return isFirstRun;
  }

  /// Save onboarding filters
  static Future<void> saveOnboardingFilters(JobSearchFilters filters) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_wasKey, filters.was);
    await prefs.setString(_woKey, filters.wo);
    await prefs.setDouble(_umkreisKey, filters.umkreis);
    await prefs.setString(_berufsfeldKey, filters.berufsfeld);
    await prefs.setString(_arbeitgeberKey, filters.arbeitgeber);
    await prefs.setString(_veroeffentlichtseitKey, filters.veroeffentlichtseit);
    await prefs.setStringList(_arbeitszeitKey, filters.arbeitszeit);
    await prefs.setStringList(_angebotsartKey, filters.angebotsartList);
    await prefs.setBool(_zeitarbeitKey, filters.zeitarbeit);
  }

  /// Load saved onboarding filters
  static Future<JobSearchFilters> loadOnboardingFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filters = JobSearchFilters();

    filters.was = prefs.getString(_wasKey) ?? '';
    filters.wo = prefs.getString(_woKey) ?? '';
    filters.umkreis = prefs.getDouble(_umkreisKey) ?? 30.0;
    filters.berufsfeld = prefs.getString(_berufsfeldKey) ?? '';
    filters.arbeitgeber = prefs.getString(_arbeitgeberKey) ?? '';
    filters.veroeffentlichtseit =
        prefs.getString(_veroeffentlichtseitKey) ?? '0';
    filters.arbeitszeit = prefs.getStringList(_arbeitszeitKey) ?? ['vz'];
    filters.angebotsartList = prefs.getStringList(_angebotsartKey) ?? ['1'];
    filters.zeitarbeit = prefs.getBool(_zeitarbeitKey) ?? false;

    return filters;
  }

  /// Reset onboarding (for testing purposes)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
