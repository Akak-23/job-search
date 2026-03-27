/// Service for sorting job listings
class JobSortingService {
  static List<Map<String, String>> sortJobs(
    List<Map<String, String>> jobs,
    String sortBy,
    bool sortAscending,
  ) {
    final sorted = List<Map<String, String>>.from(jobs);

    switch (sortBy) {
      case 'title':
        sorted.sort((a, b) {
          final titleA = a['title'] ?? '';
          final titleB = b['title'] ?? '';
          return sortAscending
              ? titleA.compareTo(titleB)
              : titleB.compareTo(titleA);
        });
        break;
      case 'company':
        sorted.sort((a, b) {
          final compA = a['arbeitgeber'] ?? '';
          final compB = b['arbeitgeber'] ?? '';
          return sortAscending
              ? compA.compareTo(compB)
              : compB.compareTo(compA);
        });
        break;
      case 'location':
        sorted.sort((a, b) {
          // Prioritize city (arbeitsort_ort) over region (arbeitsort_region)
          final cityA = a['arbeitsort_ort'] ?? '';
          final cityB = b['arbeitsort_ort'] ?? '';
          
          // Primary sort by city
          final cityComparison = sortAscending
              ? cityA.compareTo(cityB)
              : cityB.compareTo(cityA);
          
          // If cities are the same or empty, sort by company name as secondary
          if (cityComparison == 0) {
            final compA = a['arbeitgeber'] ?? '';
            final compB = b['arbeitgeber'] ?? '';
            return sortAscending
                ? compA.compareTo(compB)
                : compB.compareTo(compA);
          }
          
          return cityComparison;
        });
        break;
      case 'date':
      default:
        sorted.sort((a, b) {
          final dateA = a['aktuelleVeroeffentlichungsdatum'] ?? '';
          final dateB = b['aktuelleVeroeffentlichungsdatum'] ?? '';
          return sortAscending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
        break;
    }

    return sorted;
  }
}
