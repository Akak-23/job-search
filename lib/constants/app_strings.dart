/// Application-wide String Constants
/// 
/// This file contains all user-facing strings and internal string constants
/// to avoid magic strings throughout the codebase.
library;

// Application stages
const String stageSaved = 'Saved';
const String stageApplied = 'Applied';
const String stageInterview = 'Interview';
const String stageOffer = 'Offer';
const String stageRejected = 'Rejected';
const String stageAll = 'All';

const List<String> applicationStages = [
  stageSaved,
  stageApplied,
  stageInterview,
  stageOffer,
  stageRejected,
];

// Screen titles
const String homeScreenTitle = 'Job Search';
const String favoritesScreenTitle = 'Favorites';
const String resumeScreenTitle = 'My Resume';
const String applicationManagerTitle = 'Applications';
const String settingsScreenTitle = 'Settings';

// Dialog titles and messages
const String confirmDelete = 'Delete';
const String confirmDeleteMessage = 'Are you sure you want to delete this item?';
const String cancel = 'Cancel';
const String delete = 'Delete';
const String save = 'Save';
const String edit = 'Edit';
const String add = 'Add';
const String close = 'Close';
const String ok = 'OK';

// Success messages
const String savedSuccessfully = 'Saved successfully';
const String deletedSuccessfully = 'Deleted successfully';
const String updatedSuccessfully = 'Updated successfully';
const String copiedToClipboard = 'Copied to clipboard';
const String applicationSaved = 'Application saved';
const String applicationRemoved = 'Application removed';

// Error messages
const String errorLoadingData = 'Error loading data. Please try again.';
const String errorNetwork = 'Network error. Please check your connection.';
const String errorGeneral = 'Something went wrong. Please try again.';
const String errorNoInternetConnection = 'No internet connection available';
const String errorTimeout = 'Request timed out. Please try again.';
const String errorNotFound = 'Item not found';
const String errorUnauthorized = 'Unauthorized. Please login again.';
const String errorInvalidInput = 'Invalid input. Please check your entries.';

// Validation messages
const String emailRequired = 'Email is required';
const String emailInvalid = 'Please enter a valid email address';
const String passwordRequired = 'Password is required';
const String passwordTooShort = 'Password must be at least 6 characters';
const String passwordTooWeak = 'Password is too weak';
const String urlInvalid = 'Please enter a valid URL';
const String phoneInvalid = 'Please enter a valid phone number';
const String dateInvalid = 'Please enter a valid date';

// Empty state messages
const String noJobs = 'No jobs found';
const String noFavorites = 'No favorite jobs yet';
const String noApplications = 'No applications yet';
const String noResults = 'No results found';
const String noData = 'No data available';

// Loading messages
const String loading = 'Loading...';
const String loadingJobs = 'Loading jobs...';
const String loadingApplications = 'Loading applications...';
const String loadingMore = 'Loading more...';

// Field labels
const String titleField = 'Title';
const String descriptionField = 'Description';
const String locationField = 'Location';
const String companyField = 'Company';
const String salaryField = 'Salary';
const String experienceField = 'Experience';
const String skillsField = 'Skills';
const String emailField = 'Email';
const String phoneField = 'Phone';
const String dateField = 'Date';
const String stageField = 'Stage';
const String notesField = 'Notes';

// Placeholder texts
const String enterTitle = 'Enter title...';
const String enterDescription = 'Enter description...';
const String enterLocation = 'Enter location...';
const String enterEmail = 'Enter email address...';
const String enterPassword = 'Enter password...';
const String enterPhone = 'Enter phone number...';
const String enterSearch = 'Search jobs...';

// Date/Time related
const String today = 'Today';
const String yesterday = 'Yesterday';
const String thisWeek = 'This Week';
const String thisMonth = 'This Month';
const String older = 'Older';

// Job details - German field names (internal)
const String arbeitsort = 'arbeitsort';
const String arbeitgeber = 'arbeitgeber';
const String arbeitsortStrasse = 'arbeitsort_strasse';
const String arbeitsortPlz = 'arbeitsort_plz';
const String arbeitsortOrt = 'arbeitsort_ort';
const String arbeitsortRegion = 'arbeitsort_region';
const String arbeitsortLand = 'arbeitsort_land';
const String zeitarbeit = 'zeitarbeit';

// Job details - Short field names (used in parsing)
const String strasse = 'strasse';
const String plz = 'plz';
const String ort = 'ort';
const String region = 'region';
const String land = 'land';

// UI labels (English)
const String labelStrasse = 'Street';
const String labelPlz = 'Postal Code';
const String labelOrt = 'City';
const String labelRegion = 'Region';
const String labelLand = 'Country';
const String labelZeitarbeit = 'Temporary Work';
const String labelKeineZeitarbeit = 'No Temporary Work';
const String labelPraktikum = 'Internship';
const String labelVollzeit = 'Full-time';
const String labelTeilzeit = 'Part-time';
const String labelBefristet = 'Fixed-term';
const String labelUnbefristet = 'Permanent';

// Job type codes
const String praktikum = 'praktikum';

// Boolean value representations
const String boolTrue = 'true';
const String boolFalse = 'false';
const String boolOne = '1';
const String boolZero = '0';
const String boolJa = 'ja';
const String boolNein = 'nein';
const String boolNull = 'null';

// Sorting options
const String sortNewest = 'Newest';
const String sortOldest = 'Oldest';
const String sortSalaryHigh = 'Salary (High to Low)';
const String sortSalaryLow = 'Salary (Low to High)';
const String sortRelevance = 'Relevance';

// Filter options
const String filterAll = 'All';
const String filterFull = 'Full-time';
const String filterPart = 'Part-time';
const String filterTemporary = 'Temporary';
const String filterInternship = 'Internship';

// URL schemes and protocols
const String httpScheme = 'http';
const String httpsScheme = 'https';
const String mailtoScheme = 'mailto';
const String telScheme = 'tel';

// API endpoints (relative paths)
const String apiJobsPath = '/jobs';
const String apiApplicationsPath = '/applications';
const String apiResumeUpdatePath = '/resume';
const String apiSearchPath = '/search';
const String apiFilterPath = '/filter';

// Local storage keys
const String storageJobsKey = 'cached_jobs';
const String storageApplicationsKey = 'cached_applications';
const String storageResumeKey = 'user_resume';
const String storageFavoritesKey = 'favorite_jobs';
const String storageLastUpdateKey = 'last_update';
const String storageUserPrefsKey = 'user_preferences';

// Regex patterns (for validation)
const String emailPattern =
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
const String urlPattern =
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
const String phonePattern = r'^(\+\d{1,3}[- ]?)?\d{10,}$';

// App version and build info (can be updated with actual values)
const String appName = 'Job Search';
const String appVersion = '1.0.0';

// Miscellaneous
const String noItemSelected = 'No item selected';
const String itemsSelected = 'items selected';
const String selectAll = 'Select All';
const String deselectAll = 'Deselect All';
const String retry = 'Retry';
const String settings = 'Settings';
const String about = 'About';
const String help = 'Help';
const String feedback = 'Send Feedback';
const String logout = 'Logout';
const String login = 'Login';
const String signup = 'Sign Up';
