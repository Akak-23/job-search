import 'package:flutter/material.dart';
import '../models/saved_search.dart';
import '../services/saved_searches_service.dart';
import '../services/search_history_service.dart';

class SavedSearchesScreen extends StatefulWidget {
  final Function(SavedSearch)? onSearchSelected;

  const SavedSearchesScreen({super.key, this.onSearchSelected});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  List<SavedSearch> _savedSearches = [];
  List<SavedSearch> _recentSearches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final searches = await SavedSearchesService.getSavedSearches();
      final recent = await SearchHistoryService.getHistory();
      if (!mounted) return;
      setState(() {
        _savedSearches = searches;
        _recentSearches = recent;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _onSearchApplied() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteSearch(SavedSearch search) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Search'),
        content: Text('Remove "${search.name}" from your saved searches?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SavedSearchesService.deleteSearch(search.name);
      await _loadSavedSearches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search deleted')),
        );
      }
    }
  }

  Future<void> _renameSearch(SavedSearch search) async {
    final controller = TextEditingController(text: search.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != search.name) {
      await SavedSearchesService.renameSearch(search.name, newName);
      await _loadSavedSearches();
    }
  }

  String _getAngebotsartLabel(String value) {
    switch (value) {
      case '1':
        return 'Employment';
      case '2':
        return 'Self-employment';
      case '4':
        return 'Training';
      case '34':
        return 'Internship';
      default:
        return value;
    }
  }

  String _getArbeitszeitLabel(String value) {
    switch (value) {
      case 'vz':
        return 'Full-time';
      case 'tz':
        return 'Part-time';
      case 'ho':
        return 'Remote';
      case 'snw':
        return 'Shift/Night';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Searches'),
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'clear_recent') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Recent Searches'),
                      content: const Text(
                        'Remove all items from your recent search history?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await SearchHistoryService.clearHistory();
                    await _loadSavedSearches();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Recent searches cleared'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'clear_recent',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Clear Recent'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.history, size: 32),
                text: 'Recent',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: Icon(Icons.bookmark, size: 32),
                text: 'Saved',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
            ],
            labelPadding: const EdgeInsets.symmetric(vertical: 0),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontSize: 10),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRecentSearchesTab(),
                  _buildSavedSearchesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentSearchesTab() {
    return _recentSearches.isEmpty
        ? _buildEmptyState(
            icon: Icons.history,
            title: 'No Recent Searches',
            description: 'Your search history will appear here as you search for jobs',
            actionLabel: 'Start Searching',
            onAction: () => Navigator.pop(context),
          )
        : CustomScrollView(
            slivers: [

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final search = _recentSearches[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: _buildSearchCard(
                        search: search,
                        isRecent: true,
                        onTap: () {
                          if (widget.onSearchSelected != null) {
                            try {
                              widget.onSearchSelected!(search);
                              _onSearchApplied();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not apply search. Please try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        onDelete: () async {
                          await SearchHistoryService.removeFromHistoryAt(index);
                          await _loadSavedSearches();
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Search removed')),
                            );
                          }
                        },
                      ),
                    );
                  },
                  childCount: _recentSearches.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
  }

  Widget _buildSavedSearchesTab() {
    return _savedSearches.isEmpty
        ? _buildEmptyState(
            icon: Icons.bookmark_border,
            title: 'No Saved Searches',
            description: 'Save your favorite filters to quickly find jobs that match your preferences',
            actionLabel: 'Create a Search',
            onAction: () => Navigator.pop(context),
          )
        : CustomScrollView(
            slivers: [

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final search = _savedSearches[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: _buildSavedSearchCard(search),
                    );
                  },
                  childCount: _savedSearches.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  String _buildSearchSummary(SavedSearch search) {
    final parts = <String>[];
    if (search.was.isNotEmpty) parts.add(search.was);
    if (search.wo.isNotEmpty) parts.add(search.wo);
    if (search.berufsfeld.isNotEmpty) parts.add(search.berufsfeld);
    if (parts.isEmpty) parts.add('All filters');
    return parts.join(' • ');
  }

  Widget _buildSearchCard({
    required SavedSearch search,
    required bool isRecent,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withAlpha((0.15 * 255).round()),
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRecent
                  ? [
                      Theme.of(context).colorScheme.secondary.withAlpha((0.06 * 255).round()),
                      Colors.transparent,
                    ]
                  : [
                      Theme.of(context).colorScheme.primary.withAlpha((0.04 * 255).round()),
                      Colors.transparent,
                    ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRecent
                              ? Theme.of(context).colorScheme.secondary.withAlpha((0.15 * 255).round())
                              : Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isRecent ? Icons.history : Icons.bookmark,
                          color: isRecent
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _buildSearchSummary(search),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (search.savedAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatDateTime(search.savedAt!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSearchCriteriaTags(search),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedSearchCard(SavedSearch search) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha((0.15 * 255).round()),
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withAlpha((0.04 * 255).round()),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bookmark,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            search.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _buildSearchSummary(search),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'apply':
                            if (widget.onSearchSelected != null) {
                              widget.onSearchSelected!(search);
                              _onSearchApplied();
                            }
                            break;
                          case 'rename':
                            _renameSearch(search);
                            break;
                          case 'delete':
                            _deleteSearch(search);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'apply',
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 18),
                              SizedBox(width: 12),
                              Text('Apply'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 12),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18),
                              SizedBox(width: 12),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchCriteriaTags(search),
                const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: search.notificationsEnabled,
                      onChanged: (value) async {
                        try {
                          await SavedSearchesService.updateSearch(
                            search.name,
                            notificationsEnabled: value,
                          );
                          await _loadSavedSearches();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Notifications enabled for ${search.name}'
                                      : 'Notifications disabled',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }

  Widget _buildSearchCriteriaTags(SavedSearch search) {
    final criteria = <String>[];
    
    if (search.was.isNotEmpty) criteria.add(search.was);
    if (search.wo.isNotEmpty) criteria.add(search.wo);
    if (search.berufsfeld.isNotEmpty) criteria.add(search.berufsfeld);
    if (search.arbeitgeber.isNotEmpty) criteria.add(search.arbeitgeber);
    if (search.zeitarbeit) criteria.add('Temp Agencies');
    if (search.angebotsart.isNotEmpty) criteria.add(_getAngebotsartLabel(search.angebotsart));
    if (search.arbeitszeit.isNotEmpty) criteria.add(_getArbeitszeitLabel(search.arbeitszeit));

    if (criteria.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    
    // Add first 3 criteria as tags
    for (final tag in criteria.take(3)) {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Add "+N more" indicator if there are more than 3
    if (criteria.length > 3) {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '+${criteria.length - 3}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: children,
    );
  }
}