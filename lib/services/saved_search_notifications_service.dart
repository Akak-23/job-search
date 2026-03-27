import '../models/saved_search.dart';
import 'saved_searches_service.dart';
import 'api_service.dart';
import 'job_parsing_service.dart';
import 'notification_service.dart';

class SavedSearchNotificationsService {
  /// Check all saved searches with notifications enabled
  /// If new jobs found (count increased compared to lastResultCount), notify
  static Future<void> checkAndNotifyAll() async {
    final searches = await SavedSearchesService.getSavedSearches();
    for (final search in searches) {
      if (!search.notificationsEnabled) continue;
      try {
        final params = _buildParams(search);
        final jsonBody = await ApiService.getJobs(params);
        final jobs = await JobParsingService.parseJobResponse(jsonBody);
        final count = jobs.length;
        if (count > search.lastResultCount) {
          final newCount = count - search.lastResultCount;
          await NotificationService.show(
            title: 'New jobs for ${search.name}',
            body: '$newCount new matches found',
          );
          await SavedSearchesService.updateSearch(
            search.name,
            lastResultCount: count,
          );
        }
      } catch (_) {
        // Silently ignore errors during background check
        continue;
      }
    }
  }

  static Map<String, String> _buildParams(SavedSearch search) {
    final params = <String, String>{
      'was': search.was,
      'wo': search.wo,
      'berufsfeld': search.berufsfeld,
      'arbeitgeber': search.arbeitgeber,
      'veroeffentlichtseit': search.veroeffentlichtseit,
      'zeitarbeit': search.zeitarbeit.toString(),
      'angebotsart': search.angebotsart,
      'befristung': search.befristung,
      'arbeitszeit': search.arbeitszeit,
      'umkreis': search.umkreis.toInt().toString(),
      'page': '1',
      'size': '50',
    };
    params.removeWhere((_, value) => value.isEmpty);
    return params;
  }
}
