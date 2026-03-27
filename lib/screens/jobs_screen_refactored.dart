import 'package:flutter/material.dart';
import '../services/jobs_service.dart';
import '../services/applications_service.dart';
import '../services/saved_searches_service.dart';
import '../services/search_history_service.dart';
import '../services/onboarding_service.dart';
import '../models/saved_search.dart';
import '../widgets/job_card_refactored.dart';
import '../widgets/jobs/job_search_bar.dart';
import '../widgets/jobs/job_sorting_widget.dart';
import '../widgets/jobs/advanced_filters_section.dart';
import '../widgets/jobs/location_radius_dialog.dart';
import '../widgets/common/sliver_state_widget.dart';
import 'saved_searches_screen.dart';

class JobsScreenRefactored extends StatefulWidget {
  const JobsScreenRefactored({super.key});

  @override
  JobsScreenRefactoredState createState() => JobsScreenRefactoredState();
}

class JobsScreenRefactoredState extends State<JobsScreenRefactored>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final JobsService _jobsService = JobsService();
  late final ScrollController _scrollController;
  late final VoidCallback _savedJobsListener;

  bool _showBackToTop = false;
  bool _showAdvanced = false;
  bool _showBottomShadow = false;

  List<Map<String, String>> _favorites = [];
  List<Map<String, dynamic>> _appliedJobs = [];

  final TextEditingController _wasController = TextEditingController();
  final TextEditingController _woController = TextEditingController();
  final TextEditingController _berufsfeldController = TextEditingController();
  final TextEditingController _arbeitgeberController = TextEditingController();
  final TextEditingController _veroeffentlichtseitController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    _savedJobsListener = _loadFavorites;
    ApplicationsService.savedJobsVersion.addListener(_savedJobsListener);
    _loadFavorites();
    _initializeControllers();
    _restoreLastSearchOnStartup();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    ApplicationsService.savedJobsVersion.removeListener(_savedJobsListener);
    _wasController.dispose();
    _woController.dispose();
    _berufsfeldController.dispose();
    _arbeitgeberController.dispose();
    _veroeffentlichtseitController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload favorites when app comes back to foreground
      _loadFavorites();
    }
  }

  /// Public method to refresh favorites from outside
  void refreshFavorites() {
    _loadFavorites();
  }

  void _initializeControllers() {
    _wasController.text = _jobsService.filters.was;
    _woController.text = _jobsService.filters.wo;
    _berufsfeldController.text = _jobsService.filters.berufsfeld;
    _arbeitgeberController.text = _jobsService.filters.arbeitgeber;
    _veroeffentlichtseitController.text =
        _jobsService.filters.veroeffentlichtseit;
  }

  void _updateControllersFromFilters() {
    _wasController.text = _jobsService.filters.was;
    _woController.text = _jobsService.filters.wo;
    _berufsfeldController.text = _jobsService.filters.berufsfeld;
    _arbeitgeberController.text = _jobsService.filters.arbeitgeber;
    _veroeffentlichtseitController.text =
        _jobsService.filters.veroeffentlichtseit;
  }

  Future<void> _loadFavorites() async {
    final favs = await ApplicationsService.getSavedApplications();
    setState(
      () => _favorites = favs.map((app) {
        final filteredApp = <String, String>{};
        app.forEach((key, value) {
          if (value is String) filteredApp[key] = value;
        });
        return filteredApp;
      }).toList(),
    );
    await _loadAppliedJobs();
  }

  Future<void> _loadAppliedJobs() async {
    final appliedJobs = await ApplicationsService.loadApplications();
    setState(() => _appliedJobs = appliedJobs);
  }

  bool _jobIsFavorited(Map<String, String> job) {
    return _favorites.any(
      (e) =>
          e['title'] == job['title'] && e['description'] == job['description'],
    );
  }

  bool _jobIsApplied(Map<String, String> job) {
    return _appliedJobs.any(
      (e) =>
          e['title'] == job['title'] && e['description'] == job['description'],
    );
  }

  Future<void> _toggleFavorite(
    Map<String, String> job,
    bool isFavorited,
  ) async {
    await ApplicationsService.toggleSaved(job);
    await _loadFavorites();
  }

  Future<void> _restoreLastSearchOnStartup() async {
    try {
      // If we just completed onboarding, use those filters and search immediately
      final isFirstRun =
          await OnboardingService.consumeFirstRunAfterOnboarding();
      if (isFirstRun) {
        final onboardingFilters =
            await OnboardingService.loadOnboardingFilters();
        _jobsService.filters.was = onboardingFilters.was;
        _jobsService.filters.wo = onboardingFilters.wo;
        _jobsService.filters.umkreis = onboardingFilters.umkreis;
        _jobsService.filters.berufsfeld = onboardingFilters.berufsfeld;
        _jobsService.filters.arbeitgeber = onboardingFilters.arbeitgeber;
        _jobsService.filters.veroeffentlichtseit =
            onboardingFilters.veroeffentlichtseit;
        _jobsService.filters.arbeitszeit = onboardingFilters.arbeitszeit;
        _jobsService.filters.angebotsartList =
            onboardingFilters.angebotsartList;
        _jobsService.filters.zeitarbeit = onboardingFilters.zeitarbeit;
        _updateControllersFromFilters();
        await _fetchJobs();
        return;
      }

      // Otherwise, restore saved or last searches (does not auto-fetch yet)
      final defaultSearch = await SavedSearchesService.getDefaultSearch();
      if (defaultSearch != null) {
        _applySearchFilters(defaultSearch);
        return;
      }
      final lastSearch = await SavedSearchesService.getLastSearch();
      if (lastSearch != null) {
        _applySearchFilters(lastSearch);
      }
    } catch (e) {
      // Silently ignore errors during auto-apply
    }
  }

  void _updateFiltersFromSearch(SavedSearch search) {
    _jobsService.filters.was = search.was;
    _jobsService.filters.wo = search.wo;
    _jobsService.filters.berufsfeld = search.berufsfeld;
    _jobsService.filters.arbeitgeber = search.arbeitgeber;
    _jobsService.filters.veroeffentlichtseit = search.veroeffentlichtseit;
    _jobsService.filters.zeitarbeit = search.zeitarbeit;
    _jobsService.filters.angebotsart = search.angebotsart;
    _jobsService.filters.befristung = search.befristung;
    _jobsService.filters.arbeitszeit = search.arbeitszeit.split(';');
    _jobsService.filters.angebotsartList = search.angebotsart.split(';');
    _jobsService.filters.umkreis = search.umkreis;
    _updateControllersFromFilters();
  }

  void _applySearchFilters(SavedSearch search) {
    setState(() => _updateFiltersFromSearch(search));
  }

  SavedSearch _createSavedSearchFromCurrentFilters(
    String name, {
    bool isDefault = false,
  }) {
    return SavedSearch(
      name: name,
      was: _jobsService.filters.was,
      wo: _jobsService.filters.wo,
      berufsfeld: _jobsService.filters.berufsfeld,
      arbeitgeber: _jobsService.filters.arbeitgeber,
      veroeffentlichtseit: _jobsService.filters.veroeffentlichtseit,
      zeitarbeit: _jobsService.filters.zeitarbeit,
      angebotsart: _jobsService.filters.angebotsartList.join(';'),
      befristung: _jobsService.filters.befristung,
      arbeitszeit: _jobsService.filters.arbeitszeit.join(';'),
      umkreis: _jobsService.filters.umkreis,
      savedAt: DateTime.now(),
      isDefault: isDefault,
    );
  }

  Future<void> _saveFilter(String nickname) async {
    final search = _createSavedSearchFromCurrentFilters(nickname);
    await SavedSearchesService.saveSearch(search);
    await SavedSearchesService.autoSaveLastSearch(search);
  }

  void _applySavedSearch(SavedSearch search) {
    if (!mounted) return;
    setState(() => _updateFiltersFromSearch(search));
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      await _jobsService.fetchJobs();
      if (!mounted) return;

      final currentSearch = _createSavedSearchFromCurrentFilters(
        '__current_search__',
      );
      await SavedSearchesService.autoSaveLastSearch(currentSearch);
      await SearchHistoryService.addToHistory(currentSearch);

      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onScroll();
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = 200.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final shouldShowBackToTop = current > 400.0;
    if (shouldShowBackToTop != _showBackToTop) {
      setState(() => _showBackToTop = shouldShowBackToTop);
    }
    final shouldShowShadow =
        _jobsService.jobs.isNotEmpty && current < maxScroll - 50.0;
    if (shouldShowShadow != _showBottomShadow) {
      setState(() => _showBottomShadow = shouldShowShadow);
    }
    // Prevent auto-loading on initial empty state; only load more when jobs exist
    if (_jobsService.jobs.isNotEmpty && maxScroll - current <= threshold) {
      _loadMore();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadMore() async {
    try {
      await _jobsService.loadMore();
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onScroll();
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _showSaveFilterDialog() async {
    final TextEditingController nicknameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Filter'),
          content: TextField(
            controller: nicknameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name for this filter',
              hintText: 'e.g. "Software Developer Berlin"',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final nickname = nicknameController.text.trim();
                if (nickname.isNotEmpty) Navigator.of(context).pop(nickname);
              },
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      await _saveFilter(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter "$result" saved'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Show',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedSearchesScreen(
                      onSearchSelected: _applySavedSearch,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showLocationDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationRadiusDialog(
        initialLocation: _woController.text,
        initialRadius: _jobsService.filters.umkreis,
      ),
    );
    if (result != null) {
      setState(() {
        _jobsService.filters.wo = result['ort'] ?? '';
        _woController.text = _jobsService.filters.wo;
        _jobsService.filters.umkreis = result['umkreis'] ?? 30.0;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _jobsService.clearFilters();
      _wasController.clear();
      _woController.clear();
      _arbeitgeberController.clear();
      _berufsfeldController.clear();
      _veroeffentlichtseitController.text = '7';
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchJobs,
          color: const Color(0xFF6366F1),
          backgroundColor: Colors.white,
          strokeWidth: 3.0,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 0.0),
                sliver: SliverToBoxAdapter(child: _buildFilters()),
              ),
              if (_jobsService.isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_jobsService.isLoading)
                SliverStateWidget.loading()
              else if (_jobsService.error != null && _jobsService.jobs.isEmpty)
                SliverStateWidget.error(
                  message: _jobsService.error!,
                  onRetry: _fetchJobs,
                )
              else if (_jobsService.jobs.isEmpty)
                SliverStateWidget.empty(
                  title: 'No jobs available',
                  message:
                      'No jobs match your current filters. Try adjusting them or expanding your search radius.',
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final job = _jobsService.jobs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: JobCardRefactored(
                          title: job['title'] ?? 'No Title',
                          description: job['description'] ?? '',
                          job: job,
                          refnr: job['refnr'],
                          isFavorited: _jobIsFavorited(job),
                          isApplied: _jobIsApplied(job),
                          onFavoriteChanged: (isFav) =>
                              _toggleFavorite(job, isFav),
                        ),
                      );
                    }, childCount: _jobsService.jobs.length),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: kBottomNavigationBarHeight),
              ),
            ],
          ),
        ),
        if (_showBottomShadow)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        if (_showBackToTop)
          Positioned(
            right: 16,
            bottom: 16,
            child: AnimatedScale(
              scale: _showBackToTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Transform.scale(
                scale: 1.15,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    elevation: 0,
                    heroTag: 'scroll_to_top_fab',
                    onPressed: _scrollToTop,
                    backgroundColor: Colors.transparent,
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: _showBackToTop ? 88 : 16,
          child: Transform.scale(
            scale: 1.15,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                elevation: 0,
                heroTag: 'saved_searches_fab',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await navigator.push(
                    MaterialPageRoute(
                      builder: (context) => SavedSearchesScreen(
                        onSearchSelected: (search) {
                          _applySavedSearch(search);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (!mounted) return;
                            if (navigator.canPop()) navigator.pop();
                          });
                        },
                      ),
                    ),
                  );
                },
                backgroundColor: Colors.transparent,
                tooltip: 'Saved Searches',
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          JobSearchBar(
            wasController: _wasController,
            filters: _jobsService.filters,
            onToggleAdvanced: () =>
                setState(() => _showAdvanced = !_showAdvanced),
            onSearch: _fetchJobs,
            showAdvanced: _showAdvanced,
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 8),
            AdvancedFiltersSection(
              filters: _jobsService.filters,
              arbeitgeberController: _arbeitgeberController,
              berufsfeldController: _berufsfeldController,
              veroeffentlichtseitController: _veroeffentlichtseitController,
              onSaveFilter: _showSaveFilterDialog,
              onSearch: _fetchJobs,
              onClear: _clearFilters,
              onShowLocationDialog: _showLocationDialog,
              onArbeitszeitChanged: (value) {
                setState(() {
                  if (_jobsService.filters.arbeitszeit.contains(value)) {
                    _jobsService.filters.arbeitszeit.remove(value);
                  } else {
                    _jobsService.filters.arbeitszeit.add(value);
                  }
                });
              },
              onAngebotsartChanged: (value) {
                setState(() {
                  if (_jobsService.filters.angebotsartList.contains(value)) {
                    _jobsService.filters.angebotsartList.remove(value);
                  } else {
                    _jobsService.filters.angebotsartList.add(value);
                  }
                });
              },
              onZeitarbeitChanged: (value) {
                setState(() {
                  _jobsService.filters.zeitarbeit = value;
                });
              },
            ),
          ],
          if (_jobsService.jobs.isNotEmpty) ...[
            const SizedBox(height: 8),
            JobSortingWidget(
              sortBy: _jobsService.sortBy,
              sortAscending: _jobsService.sortAscending,
              onSortChanged: (sortKey) {
                setState(() {
                  _jobsService.changeSortOption(sortKey);
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
