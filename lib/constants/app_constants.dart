/// Application-wide constants
/// This class should not be instantiated
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // API and Pagination
  static const int pageSize = 10;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration debounceDelay = Duration(milliseconds: 500);

  // Defaults
  static const String defaultPublishedSince = '0';
  static const String defaultJobType = '1';
  static const String defaultEmploymentType = '2';
  static const String defaultWorkingHours = 'vz';
  static const double defaultRadius = 30.0;

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Sorting Options
  static const List<String> sortOptions = ['date', 'title', 'company', 'location'];

  // Application Stages
  static const List<String> applicationStages = [
    'Saved',
    'Applied',
    'Interview',
    'Offer',
    'Rejected'
  ];

  // Storage Keys
  static const String savedSearchesKey = 'saved_searches';
  static const String searchHistoryKey = 'search_history';
  static const String favoritesKey = 'favorites';
  static const String applicationsKey = 'applications';
  static const String resumeDataKey = 'resume_data';

  // Error Messages
  static const String errorLoadingJobs = 'Failed to load jobs. Please try again.';
  static const String errorNetworkConnection = 'No internet connection';
  static const String errorTimeout = 'Request timed out';
  static const String noResultsFound = 'No jobs found matching your criteria';

  // Success Messages
  static const String savedSuccessfully = 'Saved successfully';
  static const String deletedSuccessfully = 'Deleted successfully';
  static const String copiedToClipboard = 'Copied to clipboard';
}
