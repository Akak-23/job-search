import 'package:flutter/foundation.dart';
import '../models/job_search_filters.dart';
import '../services/api_service.dart';
import '../services/job_parsing_service.dart';
import '../services/job_sorting_service.dart';

/// Provider for managing jobs state and operations
class JobsProvider extends ChangeNotifier {
  final JobSearchFilters filters = JobSearchFilters();
  final int pageSize = 10;

  List<Map<String, String>> jobs = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  String sortBy = 'date';
  bool sortAscending = false;

  /// Fetch jobs from API
  Future<void> fetchJobs({int page = 1}) async {
    final isFirstPage = page <= 1;

    if (isFirstPage) {
      isLoading = true;
      error = null;
      isLoadingMore = false;
    } else {
      isLoadingMore = true;
    }
    notifyListeners();

    try {
      final params = filters.toParams(page: page, size: pageSize);
      final dynamic jsonBody = await ApiService.getJobs(params);
      final parsed = await JobParsingService.parseJobResponse(jsonBody);

      if (isFirstPage) {
        jobs = parsed;
        currentPage = 1;
      } else {
        jobs = [...jobs, ...parsed];
        currentPage = page;
      }

      hasMore = parsed.length >= pageSize;
      _applySorting();

      isLoading = false;
      isLoadingMore = false;
      error = null;
    } catch (err) {
      error = err.toString();
      isLoading = false;
      isLoadingMore = false;
      if (isFirstPage) {
        jobs = [];
      }
      hasMore = false;
    }
    notifyListeners();
  }

  /// Load next page of results
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;
    await fetchJobs(page: currentPage + 1);
  }

  /// Apply sorting to jobs
  void _applySorting() {
    if (sortBy.isEmpty) return;
    jobs = JobSortingService.sortJobs(jobs, sortBy, sortAscending);
  }

  /// Change sort option
  void changeSortOption(String newSort) {
    if (sortBy == newSort) {
      sortAscending = !sortAscending;
    } else {
      sortBy = newSort;
      sortAscending = false;
    }
    _applySorting();
    notifyListeners();
  }

  /// Update filter value
  void updateFilter(String key, String value) {
    // Update filter based on key
    switch (key) {
      case 'was':
        filters.was = value;
        break;
      case 'wo':
        filters.wo = value;
        break;
      case 'berufsfeld':
        filters.berufsfeld = value;
        break;
      case 'arbeitgeber':
        filters.arbeitgeber = value;
        break;
      case 'veroeffentlichtseit':
        filters.veroeffentlichtseit = value;
        break;
      case 'angebotsart':
        filters.angebotsart = value;
        break;
      case 'befristung':
        filters.befristung = value;
        break;
    }
    // Reset to first page when filter changes
    currentPage = 1;
    hasMore = true;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    filters.clear();
    currentPage = 1;
    hasMore = true;
    notifyListeners();
  }

  /// Reset pagination
  void resetPagination() {
    currentPage = 1;
    hasMore = true;
  }

  /// Check if jobs are empty
  bool get isEmpty => jobs.isEmpty;

  /// Get number of jobs
  int get jobCount => jobs.length;
}
