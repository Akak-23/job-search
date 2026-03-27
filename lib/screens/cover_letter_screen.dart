import 'package:flutter/material.dart';
import '../providers/cover_letter_provider.dart';
import '../widgets/resume/cover_letter_content.dart';

class CoverLetterScreen extends StatefulWidget {
  final Map<String, dynamic>? job;
  final bool returnOnSave;
  final bool autoGenerate;
  final bool autoSaveOnGenerate;

  const CoverLetterScreen({
    super.key,
    this.job,
    this.returnOnSave = false,
    this.autoGenerate = false,
    this.autoSaveOnGenerate = false,
  });

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  late CoverLetterProvider _coverLetterProvider;

  @override
  void initState() {
    super.initState();
    _coverLetterProvider = CoverLetterProvider();
    _loadData();
  }

  Future<void> _loadData() async {
    await _coverLetterProvider.loadCoverLetterData();
    await _coverLetterProvider.loadResumeData();
    _prefillFromJob();
    if (widget.autoGenerate) {
      await _coverLetterProvider.generateCoverLetter();
      if (widget.autoSaveOnGenerate) {
        await _saveAndReturn();
      }
    }
  }

  void _prefillFromJob() {
    final job = widget.job;
    if (job == null) return;

    final title = job['title']?.toString().trim() ?? '';
    final company = job['arbeitgeber']?.toString().trim() ??
        job['company']?.toString().trim() ??
        '';
    final description = job['description']?.toString().trim() ?? '';

    if (_coverLetterProvider.coverLetterData.jobTitleController.text.trim().isEmpty &&
        title.isNotEmpty) {
      _coverLetterProvider.coverLetterData.jobTitleController.text = title;
    }
    if (_coverLetterProvider.coverLetterData.companyController.text.trim().isEmpty &&
        company.isNotEmpty) {
      _coverLetterProvider.coverLetterData.companyController.text = company;
    }
    if (_coverLetterProvider.coverLetterData.jobDescriptionController.text
            .trim()
            .isEmpty &&
        description.isNotEmpty) {
      _coverLetterProvider.coverLetterData.jobDescriptionController.text =
          description;
    }
  }

  @override
  void dispose() {
    _coverLetterProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cover Letter Generator'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: CoverLetterContent(
                  provider: _coverLetterProvider,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndReturn() async {
    await _coverLetterProvider.saveCoverLetterData(silent: true);
    if (!mounted || !widget.returnOnSave) return;
    Navigator.of(context).pop({
      'recipient': _coverLetterProvider.coverLetterData.recipient,
      'company': _coverLetterProvider.coverLetterData.company,
      'jobTitle': _coverLetterProvider.coverLetterData.jobTitle,
      'body':
          _coverLetterProvider.coverLetterData.coverLetterController.text.trim(),
    });
  }

  Future<bool> _handleWillPop() async {
    if (widget.returnOnSave) {
      await _saveAndReturn();
      return false; // pop handled manually
    }

    await _coverLetterProvider.saveCoverLetterData(silent: true);
    if (!mounted) return false;
    Navigator.of(context).pop();
    return false;
  }
}