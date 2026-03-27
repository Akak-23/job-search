import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../providers/applications_provider.dart';
import '../services/applications_service.dart';
import '../utils/app_utils.dart';
import '../utils/application_stage_helper.dart';
import '../widgets/application/stage_selection_dialog.dart';
import '../screens/cover_letter_screen.dart';

/// Refactored Application Manager Screen with separated concerns
class ApplicationManagerScreenRefactored extends StatefulWidget {
  final VoidCallback? onNavigateToJobs;

  const ApplicationManagerScreenRefactored({super.key, this.onNavigateToJobs});

  @override
  State<ApplicationManagerScreenRefactored> createState() =>
      _ApplicationManagerScreenRefactoredState();
}

class _ApplicationManagerScreenRefactoredState
    extends State<ApplicationManagerScreenRefactored>
    with SingleTickerProviderStateMixin {
  late final ApplicationsProvider _applicationsProvider;
  late AnimationController _loadingController;
  late final ValueNotifier<double> _dragTiltNotifier;
  double _dragAccumulatedDx = 0.0;
  final Map<int, bool> _isDraggingMap = {};

  bool get _isLoading => _applicationsProvider.isLoading;
  String? get _error => _applicationsProvider.error;
  List<Map<String, dynamic>> get _applications =>
      _applicationsProvider.applications;
  List<Map<String, dynamic>> get _filteredApplications =>
      _applicationsProvider.filteredApplications;
  String get _filterStage => _applicationsProvider.filterStage;
  set _filterStage(String value) => _applicationsProvider.setFilterStage(value);

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _dragTiltNotifier = ValueNotifier<double>(0.0);
    _applicationsProvider = ApplicationsProvider();
    _applicationsProvider.addListener(_onApplicationsChanged);
    _loadApplications();
  }

  Future<void> _generateCoverLetter(int index) async {
    final app = _applicationsProvider.applications[index];

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (context) => CoverLetterScreen(job: app, returnOnSave: true),
      ),
    );

    if (!mounted || result == null || result.isEmpty) return;
    app['coverLetter'] = {
      ...result,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _applicationsProvider.updateApplication(index, app);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _dragTiltNotifier.dispose();
    _applicationsProvider.removeListener(_onApplicationsChanged);
    _applicationsProvider.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    await _applicationsProvider.loadApplications();
  }

  void _onApplicationsChanged() {
    setState(() {});
  }

  Future<void> _changeStage(int index) async {
    final app = _applicationsProvider.applications[index];
    final currentStage = app['stage'] ?? stageSaved;

    final newStage = await showDialog<String>(
      context: context,
      builder: (context) => StageSelectionDialog(currentStage: currentStage),
    );

    if (newStage != null && mounted) {
      app['stage'] = newStage;
      await _applicationsProvider.updateApplication(index, app);
    }
  }

  Future<void> _deleteApplication(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text(
          'Are you sure you want to delete this application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _applicationsProvider.deleteApplication(index);
      if (mounted) {
        AppUtils.showSnackBar(context, message: 'Application deleted');
      }
    }
  }

  void _showApplicationDetails(int index) {
    final app = _applicationsProvider.filteredApplications[index];
    final originalIndex = _applications.indexOf(app);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasCoverLetter = _hasCoverLetter(app);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: AppConstants.padding,
                right: AppConstants.padding,
                top: AppConstants.padding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailsHeader(app, originalIndex, setModalState),
                          const SizedBox(height: 16),
                          _buildActionButtons(originalIndex, app),
                          const SizedBox(height: 16),
                          if (hasCoverLetter) ...[
                            _buildCoverLetterSection(
                              app,
                              originalIndex,
                              setModalState,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildExtrasSection(app, originalIndex, setModalState),
                          const SizedBox(height: 16),
                          if (ApplicationStageHelper.shouldShowNotes(
                            app['stage'],
                          ))
                            _buildNotesSection(app, originalIndex, setModalState),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(int index, Map<String, dynamic> app) {
    final stage = app['stage'] ?? stageSaved;
    final canGenerateCoverLetter = stage == stageSaved || stage == 'Preparing';

    final buttons = <Widget>[];
    
    if (canGenerateCoverLetter) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateCoverLetter(index);
            },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Cover Letter'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.indigo,
            ),
          ),
        ),
      );
    }
    
    buttons.add(
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _changeStage(index);
          },
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('Change Stage'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            foregroundColor: Colors.indigo,
          ),
        ),
      ),
    );
    
    buttons.add(
      IconButton(
        onPressed: () {
          Navigator.pop(context);
          _deleteApplication(index);
        },
        icon: const Icon(Icons.delete),
        color: Colors.red,
      ),
    );

    // Insert gaps between buttons
    final buttonsWithGaps = <Widget>[];
    for (int i = 0; i < buttons.length; i++) {
      buttonsWithGaps.add(buttons[i]);
      if (i < buttons.length - 1) {
        buttonsWithGaps.add(const SizedBox(width: 8));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: buttonsWithGaps,
    );
  }

  Widget _buildDetailsHeader(
    Map<String, dynamic> app,
    int index,
    StateSetter setModalState,
  ) {
    final stageColor = ApplicationStageHelper.getStageColor(app['stage']);
    final stageIcon = _getStageIcon(app['stage']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stageColor.withValues(alpha: 0.1),
            stageColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stageColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stageIcon, color: stageColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (app['arbeitgeber'] != null &&
                        app['arbeitgeber'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        app['arbeitgeber'].toString(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: stageColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stageIcon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  app['stage'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasSection(
    Map<String, dynamic> app,
    int index,
    StateSetter setModalState,
  ) {
    return Column(
      children: [
        _buildSingleFieldCard(
          app: app,
          index: index,
          setModalState: setModalState,
          fieldKey: 'correspondent',
          title: 'Correspondent',
          icon: Icons.contact_mail_outlined,
          hint: 'Name, email or contact person',
        ),
        const SizedBox(height: 12),
        _buildSingleFieldCard(
          app: app,
          index: index,
          setModalState: setModalState,
          fieldKey: 'salary',
          title: 'Salary',
          icon: Icons.payments_outlined,
          hint: 'e.g. 65k, 70-80k, or empty',
        ),
      ],
    );
  }

  Widget _buildSingleFieldCard({
    required Map<String, dynamic> app,
    required int index,
    required StateSetter setModalState,
    required String fieldKey,
    required String title,
    required IconData icon,
    required String hint,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        final controller = TextEditingController(
          text: app[fieldKey]?.toString() ?? '',
        );
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: fieldKey == 'salary' ? 1 : 2,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.indigo,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) async {
                    app[fieldKey] = value;
                    await ApplicationsService.updateApplication(index, app);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesSection(
    Map<String, dynamic> app,
    int index,
    StateSetter setModalState,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        final TextEditingController notesController = TextEditingController(
          text: app['note']?.toString() ?? '',
        );
        notesController.selection = TextSelection.fromPosition(
          TextPosition(offset: notesController.text.length),
        );

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 20,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Add your notes here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.indigo,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) async {
                    app['note'] = value;
                    await ApplicationsService.updateApplication(index, app);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverLetterSection(
    Map<String, dynamic> app,
    int index,
    StateSetter setModalState,
  ) {
    final coverLetter = app['coverLetter'] as Map<String, dynamic>?;
    final hasData = _hasCoverLetter(app);

    if (!hasData || coverLetter == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cover Letter',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editCoverLetter(app, index, setModalState),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (coverLetter['recipient']?.toString().isNotEmpty == true)
              _buildInfoRow('To:', coverLetter['recipient'].toString()),
            if (coverLetter['company']?.toString().isNotEmpty == true)
              _buildInfoRow('Company:', coverLetter['company'].toString()),
            if (coverLetter['jobTitle']?.toString().isNotEmpty == true)
              _buildInfoRow('Role:', coverLetter['jobTitle'].toString()),
            if (coverLetter['body']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  coverLetter['body'].toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
            if (coverLetter['updatedAt']?.toString().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Updated ${_formatDate(coverLetter['updatedAt'].toString())}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasCoverLetter(Map<String, dynamic> app) {
    final coverLetter = app['coverLetter'] as Map<String, dynamic>?;

    return coverLetter != null &&
        (coverLetter['recipient']?.toString().isNotEmpty == true ||
            coverLetter['company']?.toString().isNotEmpty == true ||
            coverLetter['jobTitle']?.toString().isNotEmpty == true ||
            coverLetter['body']?.toString().isNotEmpty == true);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _editCoverLetter(
    Map<String, dynamic> app,
    int index,
    StateSetter setModalState,
  ) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (context) => CoverLetterScreen(job: app, returnOnSave: true),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setModalState(() {
        app['coverLetter'] = {
          ...result,
          'updatedAt': DateTime.now().toIso8601String(),
        };
      });
      await ApplicationsService.updateApplication(index, app);
      if (mounted) {
        AppUtils.showSnackBar(context, message: 'Cover letter updated');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _loadingController,
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              const Text(loadingApplications),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('$errorGeneral $_error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadApplications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _filteredApplications.isEmpty
                ? _buildEmptyState()
                : Stack(
                    children: [
                      // Main list
                      ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                        itemCount: _filteredApplications.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApplications[index];
                          final originalIndex = _applications.indexOf(app);

                          return _buildApplicationCard(
                            index,
                            app,
                            originalIndex,
                          );
                        },
                      ),
                      // Left edge drag target
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails:
                              (
                                DragTargetDetails<Map<String, dynamic>> details,
                              ) {
                                _onDragAcceptToLeft(details.data);
                              },
                          builder: (context, candidateData, rejectedData) {
                            final isHovering = candidateData.isNotEmpty;
                            return Container(
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: isHovering
                                    ? LinearGradient(
                                        colors: [
                                          Colors.blue.withValues(alpha: 0.3),
                                          Colors.blue.withValues(alpha: 0.0),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: isHovering
                                      ? Colors.blue
                                      : Colors.transparent,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Right edge drag target
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails:
                              (
                                DragTargetDetails<Map<String, dynamic>> details,
                              ) {
                                _onDragAcceptToRight(details.data);
                              },
                          builder: (context, candidateData, rejectedData) {
                            final isHovering = candidateData.isNotEmpty;
                            return Container(
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: isHovering
                                    ? LinearGradient(
                                        colors: [
                                          Colors.green.withValues(alpha: 0.0),
                                          Colors.green.withValues(alpha: 0.3),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: isHovering
                                      ? Colors.green
                                      : Colors.transparent,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final showFilterMessage = _filterStage != 'All';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              showFilterMessage ? Icons.filter_list_off : Icons.inbox_outlined,
              size: 72,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            showFilterMessage
                ? 'No Applications in This Stage'
                : 'No Applications Yet',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              showFilterMessage
                  ? 'Try selecting a different filter to see\napplications in other stages.'
                  : 'Start applying to jobs from the Jobs tab\nto track your progress here.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: showFilterMessage
                  ? () => setState(() => _filterStage = 'All')
                  : widget.onNavigateToJobs,
              icon: Icon(
                showFilterMessage ? Icons.clear_all : Icons.work_outline,
                size: 22,
              ),
              label: Text(
                showFilterMessage ? 'Clear Filter' : 'Browse Jobs',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final stages = ['All', ...ApplicationStageHelper.stages];

    // Count applications per stage
    int getCountForStage(String stage) {
      if (stage == 'All') return _applications.length;
      return _applications.where((app) => app['stage'] == stage).length;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stages.map((stage) {
            final isSelected = _filterStage == stage;
            final count = getCountForStage(stage);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _filterStage = stage);
                },
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stage,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                selectedColor: Colors.indigo,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                side: BorderSide(
                  color: isSelected ? Colors.indigo : Colors.grey[300]!,
                  width: 1,
                ),
                elevation: isSelected ? 4 : 0,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
    int index,
    Map<String, dynamic> app,
    int originalIndex,
  ) {
    final stage = app['stage'] ?? stageSaved;
    final stageColor = ApplicationStageHelper.getStageColor(stage);
    final stageIcon = _getStageIcon(stage);
    final cardWidth = MediaQuery.of(context).size.width - 24;

    final isDragging = _isDraggingMap[originalIndex] ?? false;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: LongPressDraggable<Map<String, dynamic>>(
        data: {'app': app, 'originalIndex': originalIndex, 'stage': stage},
        onDragStarted: () {
          setState(() {
            _isDraggingMap[originalIndex] = true;
          });
          _dragTiltNotifier.value = 0.0;
          _dragAccumulatedDx = 0.0;
        },
        onDragUpdate: (details) {
          _dragAccumulatedDx += details.delta.dx;
          _dragTiltNotifier.value = (_dragAccumulatedDx / 300).clamp(
            -0.18,
            0.18,
          );
        },
        onDragEnd: (_) {
          _dragTiltNotifier.value = 0.0;
          _dragAccumulatedDx = 0.0;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _isDraggingMap[originalIndex] = false;
              });
            }
          });
        },
        onDraggableCanceled: (_, unusedDragUpdateDetails) {
          _dragTiltNotifier.value = 0.0;
          _dragAccumulatedDx = 0.0;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _isDraggingMap[originalIndex] = false;
              });
            }
          });
        },
        feedback: ValueListenableBuilder<double>(
          valueListenable: _dragTiltNotifier,
          builder: (context, tilt, child) {
            return Transform.rotate(angle: tilt, child: child);
          },
          child: Material(
            color: Colors.transparent,
            elevation: 12,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(color: stageColor, width: 5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCardContent(
                      context,
                      app,
                      originalIndex,
                      stage,
                      stageColor,
                      stageIcon,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        feedbackOffset: const Offset(0, -12),
        childWhenDragging: AnimatedOpacity(
          opacity: 0.3,
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            color: Colors.grey[100],
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: stageColor, width: 5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCardContent(
                  context,
                  app,
                  originalIndex,
                  stage,
                  stageColor,
                  stageIcon,
                ),
              ),
            ),
          ),
        ),
        child: AnimatedOpacity(
          opacity: isDragging ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            color: Colors.white,
            child: InkWell(
              onTap: () => _showApplicationDetails(index),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: stageColor, width: 5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCardContent(
                    context,
                    app,
                    originalIndex,
                    stage,
                    stageColor,
                    stageIcon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    Map<String, dynamic> app,
    int originalIndex,
    String stage,
    Color stageColor,
    IconData stageIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobAvatar(context, app),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(stageIcon, color: stageColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app['title'] ?? 'No Title',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (app['arbeitgeber'] != null)
                    Text(
                      app['arbeitgeber'].toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: stageColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            stage,
            style: TextStyle(
              color: stageColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case stageSaved:
        return Icons.bookmark;
      case 'Preparing':
        return Icons.edit_document;
      case 'Application Sent':
        return Icons.send;
      case 'Follow-up Phone Call':
        return Icons.phone;
      case stageInterview:
        return Icons.people;
      case 'Negotiations':
        return Icons.handshake;
      case 'Accepted':
        return Icons.check_circle;
      case 'Declined':
        return Icons.close;
      default:
        return Icons.description;
    }
  }

  Widget _buildJobAvatar(BuildContext context, Map<String, dynamic> app) {
    final title = app['title']?.toString().trim() ?? '';
    final initials = _initials(title);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'J' : initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _initials(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  /// Get the next stage when dragging right
  String? _getNextStage(String currentStage) {
    final stages = ApplicationStageHelper.stages;
    final currentIndex = stages.indexOf(currentStage);
    if (currentIndex >= 0 && currentIndex < stages.length - 1) {
      return stages[currentIndex + 1];
    }
    return null;
  }

  /// Get the previous stage when dragging left
  String? _getPreviousStage(String currentStage) {
    final stages = ApplicationStageHelper.stages;
    final currentIndex = stages.indexOf(currentStage);
    if (currentIndex > 0) {
      return stages[currentIndex - 1];
    }
    return null;
  }

  /// Handle drag accept from right (move to next stage)
  Future<void> _onDragAcceptToRight(Map<String, dynamic> dragData) async {
    final app = dragData['app'] as Map<String, dynamic>;
    final originalIndex = dragData['originalIndex'] as int;
    final currentStage = dragData['stage'] as String;

    final nextStage = _getNextStage(currentStage);
    if (nextStage == null) {
      if (mounted) {
        AppUtils.showSnackBar(context, message: 'Already at the final stage');
      }
      return;
    }

    app['stage'] = nextStage;
    await _applicationsProvider.updateApplication(originalIndex, app);
  }

  /// Handle drag accept from left (move to previous stage)
  Future<void> _onDragAcceptToLeft(Map<String, dynamic> dragData) async {
    final app = dragData['app'] as Map<String, dynamic>;
    final originalIndex = dragData['originalIndex'] as int;
    final currentStage = dragData['stage'] as String;

    final previousStage = _getPreviousStage(currentStage);
    if (previousStage == null) {
      if (mounted) {
        AppUtils.showSnackBar(context, message: 'Already at the initial stage');
      }
      return;
    }

    app['stage'] = previousStage;
    await _applicationsProvider.updateApplication(originalIndex, app);
  }
}
