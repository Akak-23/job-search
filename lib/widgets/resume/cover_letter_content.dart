import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_colors.dart';
import '../../models/cover_letter_data.dart';
import '../../providers/cover_letter_provider.dart';

class CoverLetterContent extends StatefulWidget {
  final CoverLetterProvider provider;

  const CoverLetterContent({
    super.key,
    required this.provider,
  });

  @override
  State<CoverLetterContent> createState() => _CoverLetterContentState();
}

class _CoverLetterContentState extends State<CoverLetterContent> {
  /// Spacing constants
  static const double _largeSpacing = 16;
  static const double _mediumSpacing = 12;
  static const double _smallSpacing = 8;
  static const double _iconSize = 18;
  static const double _borderRadius = 12;
  static const double _buttonPadding = 10;
  static const Duration _autoSaveDelay = Duration(milliseconds: 800);

  bool _showAdvancedSettings = false;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _customInstructionsController;
  Timer? _autoSaveTimer;

  List<TextEditingController> get _trackedControllers => [
        widget.provider.coverLetterData.jobTitleController,
        widget.provider.coverLetterData.companyController,
        widget.provider.coverLetterData.requirementsController,
        widget.provider.coverLetterData.experienceController,
        widget.provider.coverLetterData.jobDescriptionController,
        widget.provider.coverLetterData.coverLetterController,
        widget.provider.coverLetterData.recipientController,
        widget.provider.coverLetterData.bodyController,
      ];

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onProviderChanged);
    _apiKeyController = TextEditingController(
      text: widget.provider.coverLetterData.apiKey,
    );
    _customInstructionsController = TextEditingController(
      text: widget.provider.coverLetterData.customInstructions,
    );
    _setupAutoSaveListeners();
  }

  @override
  void dispose() {
    _teardownAutoSaveListeners();
    _autoSaveTimer?.cancel();
    widget.provider.removeListener(_onProviderChanged);
    _apiKeyController.dispose();
    _customInstructionsController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    final data = widget.provider.coverLetterData;
    if (_apiKeyController.text != data.apiKey) {
      _apiKeyController.text = data.apiKey;
    }
    if (_customInstructionsController.text != data.customInstructions) {
      _customInstructionsController.text = data.customInstructions;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResumeDataSection(theme),
        const SizedBox(height: _largeSpacing),
        _buildJobInfoSection(theme),
        const SizedBox(height: _largeSpacing),
        _buildProviderSection(theme),
        if (_showAdvancedSettings) ...[
          const SizedBox(height: _largeSpacing),
          _buildAdvancedSettings(theme),
        ],
        const SizedBox(height: _largeSpacing),
        _buildCoverLetterEditor(theme),
        const SizedBox(height: _largeSpacing),
        _buildActions(theme),
        if (widget.provider.error != null ||
            widget.provider.successMessage != null) ...[
          const SizedBox(height: _mediumSpacing),
          _buildStatusBanner(theme),
        ],
      ],
    );
  }

  Widget _buildResumeDataSection(ThemeData theme) {
    final data = widget.provider.coverLetterData;
    final hasResumeData =
        data.skills.isNotEmpty ||
        data.workExperience.isNotEmpty ||
        data.education.isNotEmpty;

    return _buildSectionCard(
      theme: theme,
      title: 'Resume Data',
      icon: Icons.description_outlined,
      accent: AppColors.success,
      trailing: TextButton.icon(
        onPressed: () => _loadResumeData(),
        icon: const Icon(Icons.refresh, size: _iconSize),
        label: const Text('Load'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(horizontal: _mediumSpacing, vertical: _buttonPadding),
        ),
      ),
      children: [
        if (hasResumeData)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: _smallSpacing,
                runSpacing: _smallSpacing,
                children: _buildResumePills(data),
              ),
              const SizedBox(height: _mediumSpacing),
              Text(
                'Loaded from your resume. Update your resume to refresh this data.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          )
        else
          Text(
            'No resume data loaded. Tap Load to import from your resume.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildResumePills(CoverLetterData data) {
    final pills = <Widget>[];
    
    if (data.skills.isNotEmpty) {
      pills.add(
        _infoPill(
          'Skills',
          _formatListPreview(data.skills),
        ),
      );
    }
    
    if (data.workExperience.isNotEmpty) {
      pills.add(
        _infoPill(
          'Experience',
          '${data.workExperience.length} position(s)',
        ),
      );
    }
    
    if (data.education.isNotEmpty) {
      pills.add(
        _infoPill(
          'Education',
          '${data.education.length} record(s)',
        ),
      );
    }
    
    return pills;
  }

  String _formatListPreview(List<String> items, {int limit = 3}) {
    if (items.isEmpty) return '';
    final preview = items.take(limit).join(', ');
    return items.length > limit ? '$preview...' : preview;
  }

  Widget _buildJobInfoSection(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Job Information',
      icon: Icons.work_outline,
      children: [
        _buildJobTextField(
          controller: widget.provider.coverLetterData.jobTitleController,
          label: 'Job Title *',
          hint: 'e.g., Senior Software Engineer',
          maxLines: 1,
        ),
        const SizedBox(height: _mediumSpacing),
        _buildJobTextField(
          controller: widget.provider.coverLetterData.companyController,
          label: 'Company Name *',
          hint: 'e.g., Tech Corp',
          maxLines: 1,
        ),
        const SizedBox(height: _mediumSpacing),
        _buildJobTextField(
          controller: widget.provider.coverLetterData.requirementsController,
          label: 'Key Requirements/Skills',
          hint: 'e.g., Python, React, Team Leadership',
          maxLines: 2,
        ),
        const SizedBox(height: _mediumSpacing),
        _buildJobTextField(
          controller: widget.provider.coverLetterData.experienceController,
          label: 'Your Relevant Experience',
          hint: 'e.g., 5 years in web development...',
          maxLines: 2,
        ),
        const SizedBox(height: _mediumSpacing),
        _buildJobTextField(
          controller: widget.provider.coverLetterData.jobDescriptionController,
          label: 'Job Description (Optional)',
          hint: 'Paste the job description for a tailored letter.',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildJobTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      textInputAction: maxLines == 1 ? TextInputAction.next : null,
      maxLines: maxLines,
      onChanged: (_) => _scheduleAutoSave(),
    );
  }

  Widget _buildProviderSection(ThemeData theme) {
    final providers = widget.provider.getAvailableProviders();

    return _buildSectionCard(
      theme: theme,
      title: 'AI Provider',
      icon: Icons.auto_awesome,
      accent: AppColors.secondary,
      trailing: TextButton.icon(
        onPressed: () =>
            setState(() => _showAdvancedSettings = !_showAdvancedSettings),
        icon: Icon(
          _showAdvancedSettings ? Icons.expand_less : Icons.tune,
          size: _iconSize,
        ),
        label: Text(_showAdvancedSettings ? 'Hide advanced' : 'Advanced'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(horizontal: _mediumSpacing, vertical: _buttonPadding),
        ),
      ),
      children: [
        DropdownButtonFormField<String>(
          initialValue: widget.provider.coverLetterData.selectedProvider,
          decoration: const InputDecoration(labelText: 'Select provider'),
          items: providers
              .map(
                (provider) => DropdownMenuItem(
                  value: provider,
                  child: Text(widget.provider.getProviderDisplayName(provider)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              widget.provider.setProvider(value);
              widget.provider.clearMessages();
              _scheduleAutoSave();
            }
          },
        ),
        const SizedBox(height: _mediumSpacing),
        _buildProviderInstructions(theme),
      ],
    );
  }

  Widget _buildAdvancedSettings(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Advanced Settings',
      icon: Icons.security_outlined,
      accent: AppColors.warning,
      children: [
        TextField(
          controller: _apiKeyController,
          decoration: const InputDecoration(
            labelText: 'API Key',
            helperText: 'Required for OpenAI/Claude/Custom',
          ),
          obscureText: true,
          onChanged: (value) {
            widget.provider.setApiKey(value);
            _scheduleAutoSave();
          },
        ),
        const SizedBox(height: _mediumSpacing),
        TextField(
          controller: _customInstructionsController,
          decoration: const InputDecoration(
            labelText: 'Custom Instructions',
            hintText: 'Optional: tone, focus areas, etc.',
          ),
          maxLines: 3,
          onChanged: (value) {
            widget.provider.setCustomInstructions(value);
            _scheduleAutoSave();
          },
        ),
      ],
    );
  }

  Widget _buildProviderInstructions(ThemeData theme) {
    final provider = widget.provider.coverLetterData.selectedProvider;
    final description = widget.provider.getProviderDescription(provider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_mediumSpacing),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.provider.getProviderDisplayName(provider),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: _smallSpacing / 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverLetterEditor(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      title: 'Cover Letter Content',
      icon: Icons.edit_outlined,
      children: [
        TextField(
          controller: widget.provider.coverLetterData.coverLetterController,
          decoration: const InputDecoration(
            labelText: 'Cover letter',
            hintText:
                'Your generated cover letter will appear here. You can also write manually.',
          ),
          minLines: 8,
          maxLines: 14,
          onChanged: (_) => _scheduleAutoSave(),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    final isLoading = widget.provider.isLoading;
    final isExporting = widget.provider.isExporting;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(_largeSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: isLoading ? null : _generateCoverLetter,
              icon: _buildLoadingOrIcon(isLoading, Icons.auto_awesome),
              label: Text(isLoading ? 'Generating...' : 'Generate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: _mediumSpacing),
            if (!kIsWeb)
              OutlinedButton.icon(
                onPressed: isExporting ? null : _shareCoverLetter,
                icon: _buildLoadingOrIcon(isExporting, Icons.share_outlined),
                label: Text(isExporting ? 'Sharing...' : 'Share Cover Letter'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )
            else
              const Text(
                'Sharing/exporting PDFs is not supported on web.',
                style: TextStyle(fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOrIcon(bool isLoading, IconData icon) {
    if (isLoading) {
      return const SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Icon(icon, size: _iconSize);
  }

  Widget _buildStatusBanner(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.provider.error != null)
          _statusChip(
            icon: Icons.error_outline,
            color: AppColors.error,
            text: widget.provider.error!,
          ),
        if (widget.provider.successMessage != null)
          _statusChip(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            text: widget.provider.successMessage!,
          ),
      ],
    );
  }

  Widget _statusChip({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: _smallSpacing),
      padding: const EdgeInsets.all(_mediumSpacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: _smallSpacing),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _mediumSpacing, vertical: _smallSpacing),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color accent = AppColors.primary,
    Widget? trailing,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(_largeSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) _buildIconBadge(icon, accent),
                if (icon != null) const SizedBox(width: _buttonPadding),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: _mediumSpacing),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(_buttonPadding),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: accent, size: _iconSize),
    );
  }

  void _generateCoverLetter() {
    widget.provider.clearMessages();

    if (!_validateJobInput()) {
      return;
    }

    widget.provider.generateCoverLetter();
  }

  bool _validateJobInput() {
    final jobTitle = widget.provider.coverLetterData.jobTitleController.text
        .trim();
    final company =
        widget.provider.coverLetterData.companyController.text.trim();

    if (jobTitle.isEmpty) {
      _showSnackBarMessage(
        'Please enter a job title',
        Theme.of(context).colorScheme.error,
      );
      return false;
    }

    if (company.isEmpty) {
      _showSnackBarMessage(
        'Please enter a company name',
        Theme.of(context).colorScheme.error,
      );
      return false;
    }

    return true;
  }

  Future<void> _shareCoverLetter() async {
    widget.provider.clearMessages();

    if (!_validateCoverLetterContent()) {
      return;
    }

    await widget.provider.shareCoverLetter();
  }

  bool _validateCoverLetterContent() {
    final content = widget.provider.coverLetterData.coverLetterController.text
        .trim();

    if (content.isEmpty) {
      _showSnackBarMessage(
        'Please generate or write a cover letter first',
        Theme.of(context).colorScheme.error,
      );
      return false;
    }

    return true;
  }

  Future<void> _loadResumeData() async {
    widget.provider.clearMessages();
    final scheme = Theme.of(context).colorScheme;

    _showSnackBarMessage(
      'Loading resume data...',
      scheme.primary,
      duration: const Duration(seconds: 1),
    );

    await widget.provider.loadResumeData();

    if (!mounted) return;

    if (widget.provider.error != null) {
      _showSnackBarMessage(widget.provider.error!, scheme.error);
    } else {
      _showSnackBarMessage(
        'Resume data loaded successfully!',
        scheme.secondary,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showSnackBarMessage(
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  void _setupAutoSaveListeners() {
    for (final controller in _trackedControllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _teardownAutoSaveListeners() {
    for (final controller in _trackedControllers) {
      controller.removeListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, _autoSave);
  }

  Future<void> _autoSave() async {
    await widget.provider.saveCoverLetterData(silent: true);
  }
}
