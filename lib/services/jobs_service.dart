import 'dart:async';

import '../services/api_service.dart';
import '../services/job_parsing_service.dart';
import '../services/job_sorting_service.dart';
import '../models/job_search_filters.dart';

/// Service for managing job search state and operations
class JobsService {
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

  // Debounce timer for search requests
  Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  /// Fetch jobs from API with debouncing
  Future<void> fetchJobs({int page = 1, bool debounce = true}) async {
    final isFirstPage = page <= 1;

    if (isFirstPage) {
      isLoading = true;
      error = null;
      isLoadingMore = false;
    } else {
      isLoadingMore = true;
    }

    try {
      final params = filters.toParams(page: page, size: pageSize);
      
      // Debounce first page requests to avoid rapid successive calls
      if (debounce && isFirstPage) {
        _debounceTimer?.cancel();
        await Future.delayed(_debounceDelay);
      }

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
    } catch (err) {
      error = err.toString();
      isLoading = false;
      isLoadingMore = false;
      hasMore = false;
      return;
    }
  }

  /// Load next page of results
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;
    await fetchJobs(page: currentPage + 1);
  }

  /// Change sort option
  void changeSortOption(String newSortBy) {
    if (sortBy == newSortBy) {
      sortAscending = !sortAscending;
    } else {
      sortBy = newSortBy;
      sortAscending = newSortBy == 'title' || 
                      newSortBy == 'company' || 
                      newSortBy == 'location';
    }
    _applySorting();
  }

  void _applySorting() {
    jobs = JobSortingService.sortJobs(jobs, sortBy, sortAscending);
  }

  /// Clear all filters
  void clearFilters() {
    filters.clear();
    jobs = [];
    currentPage = 1;
    hasMore = true;
  }
}
