import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/period_entry.dart';
import '../models/skill_entry.dart';
import '../models/skill_section.dart';
import '../models/language_entry.dart';
import '../models/profile_link.dart';
import '../providers/resume_provider.dart';
import '../services/resume_pdf_service.dart';
import '../services/resume_data_service.dart';
import '../services/cover_letter_service.dart';
import '../services/cover_letter_pdf_service.dart';
import '../models/cover_letter_data.dart';
import '../widgets/resume/period_entry_dialog.dart';
import '../widgets/resume/language_entry_dialog.dart';
import 'cover_letter_screen.dart';

enum ExportVisualState { idle, loading, success, error }

/// Refactored Resume Screen with separated concerns
class ResumeScreenRefactored extends StatefulWidget {
  const ResumeScreenRefactored({super.key});

  @override
  State<ResumeScreenRefactored> createState() => _ResumeScreenRefactoredState();
}

class _ResumeScreenRefactoredState extends State<ResumeScreenRefactored> {
  final _formKey = GlobalKey<FormState>();
  late ResumeProvider _resumeProvider;

  final List<PeriodEntry> _workEntries = [];
  final List<PeriodEntry> _educationEntries = [];
  final List<SkillSection> _skillSections = [];
  final List<LanguageEntry> _languageEntries = [];
  final List<ProfileLink> _profileLinks = [];

  // Track expanded sections
  bool _isEditProfileExpanded = false;
  bool _isWorkExperienceExpanded = false;
  bool _isEducationExpanded = false;
  bool _isSkillsExpanded = false;
  bool _isLanguagesExpanded = false;
  bool _isProfileLinksExpanded = false;
  bool _isCoverLetterExpanded = false;
  bool _isExportExpanded = false;
  bool _isExporting = false;
  ExportVisualState _exportState = ExportVisualState.idle;
  bool _isExportingCoverLetter = false;
  ExportVisualState _coverLetterExportState = ExportVisualState.idle;
  bool _isExportingPackage = false;
  ExportVisualState _packageExportState = ExportVisualState.idle;
  Timer? _exportStateResetTimer;

  @override
  void initState() {
    super.initState();
    _resumeProvider = ResumeProvider();
    _resumeProvider.addListener(_onResumeChanged);
    _loadData();
  }

  (String firstName, String lastName) _parseFullName() {
    final nameParts = _resumeProvider.personalData.firstNameController.text
        .trim()
        .split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    return (firstName, lastName);
  }

  String _sanitizeCoverLetterText(String text) {
    return text
        .replaceAll('•', '-')
        .replaceAll('▪', '-')
        .replaceAll('◦', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('Sincerely,', '')
        .replaceAll('Sincerely', '');
  }

  bool _validatePackageData() {
    _syncBulletPoints();

    final workErr = ResumeDataService.validatePeriodEntries(
      _workEntries,
      'Work',
    );
    if (workErr != null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(workErr)));
      return false;
    }

    final eduErr = ResumeDataService.validatePeriodEntries(
      _educationEntries,
      'Education',
    );
    if (eduErr != null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(eduErr)));
      return false;
    }

    return true;
  }

  void _handleExportError(String message, void Function() setErrorState) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (mounted) setState(setErrorState);
  }

  void _finishExport(void Function() resetExportingFlag) {
    if (!mounted) return;
    setState(resetExportingFlag);
    _scheduleExportStateReset();
  }

  void _disposeAllEntries() {
    for (final e in _workEntries) {
      e.dispose();
    }
    for (final e in _educationEntries) {
      e.dispose();
    }
    for (final section in _skillSections) {
      section.dispose();
    }
    for (final e in _languageEntries) {
      e.dispose();
    }
    for (final link in _profileLinks) {
      link.dispose();
    }
  }

  void _clearAllEntries() {
    _workEntries.clear();
    _educationEntries.clear();
    _skillSections.clear();
    _languageEntries.clear();
    _profileLinks.clear();
  }

  @override
  void dispose() {
    _exportStateResetTimer?.cancel();
    _resumeProvider.removeListener(_onResumeChanged);
    _resumeProvider.dispose();
    _disposeAllEntries();
    super.dispose();
  }

  void _onResumeChanged() {
    setState(() {});
  }

  Future<void> _loadData() async {
    await _resumeProvider.loadResumeData();

    // Dispose existing entries before reloading
    _disposeAllEntries();
    _clearAllEntries();

    // Load persisted entries
    final work = await ResumeDataService.loadWorkEntries();
    final edu = await ResumeDataService.loadEducationEntries();
    final sections = await ResumeDataService.loadSkillSections();
    final langs = await ResumeDataService.loadLanguageEntries();
    final links = await ResumeDataService.loadProfileLinks();

    setState(() {
      _workEntries.addAll(work);
      _educationEntries.addAll(edu);
      _skillSections.addAll(sections);
      _languageEntries.addAll(langs);
      _profileLinks.addAll(links);
    });

    // Add auto-save listeners
    _setupAutoSaveListeners();
  }

  void _setupAutoSaveListeners() {
    _resumeProvider.personalData.firstNameController.addListener(_saveData);
    _resumeProvider.personalData.birthDateController.addListener(_saveData);
    _resumeProvider.personalData.birthPlaceController.addListener(_saveData);
    _resumeProvider.personalData.streetController.addListener(_saveData);
    _resumeProvider.personalData.houseNumberController.addListener(_saveData);
    _resumeProvider.personalData.postalCodeController.addListener(_saveData);
    _resumeProvider.personalData.cityController.addListener(_saveData);
    _resumeProvider.personalData.emailController.addListener(_saveData);
    _resumeProvider.personalData.phoneController.addListener(_saveData);

    for (final e in _workEntries) {
      e.titleController.addListener(_saveData);
      e.companyController.addListener(_saveData);
      e.bulletsController.addListener(_saveData);
    }
    for (final e in _educationEntries) {
      e.titleController.addListener(_saveData);
      e.companyController.addListener(_saveData);
      e.bulletsController.addListener(_saveData);
    }
    for (final section in _skillSections) {
      section.titleController.addListener(_saveData);
      for (final skill in section.skills) {
        skill.nameController.addListener(_saveData);
      }
    }
    for (final e in _languageEntries) {
      // Ensure auto-add behavior on last language entry after load
      e.nameController.addListener(() => _onLanguageChanged(e));
    }
    for (final link in _profileLinks) {
      link.labelController.addListener(_saveData);
      link.urlController.addListener(_saveData);
    }
  }

  Future<void> _saveData() async {
    _syncBulletPoints();
    await _resumeProvider.saveResumeData();
    await ResumeDataService.saveWorkEntries(_workEntries);
    await ResumeDataService.saveEducationEntries(_educationEntries);
    await ResumeDataService.saveSkillSections(_skillSections);
    await ResumeDataService.saveLanguageEntries(_languageEntries);
    await ResumeDataService.saveProfileLinks(_profileLinks);
  }

  void _syncBulletPoints() {
    List<String> split(String text) => text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final e in _workEntries) {
      e.bulletPoints = split(e.bulletsController.text);
    }
    for (final e in _educationEntries) {
      e.bulletPoints = split(e.bulletsController.text);
    }
  }

  void _addWorkEntry() async {
    final e = PeriodEntry();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PeriodEntryDialog(entry: e),
    );

    if (result != null) {
      e.titleController.text = result['title'];
      e.companyController.text = result['company'] ?? '';
      e.startMonth = result['startMonth'];
      e.startYearController.text = result['startYear'];
      e.isPresent = result['isPresent'];
      e.endMonth = result['endMonth'];
      e.endYearController.text = result['endYear'];
      e.pdfPath = result['pdfPath'];
      e.bulletPoints = (result['bullets'] as List<String>?) ?? [];
      e.bulletsController.text = e.bulletPoints.join('\n');
      e.titleController.addListener(_saveData);
      e.companyController.addListener(_saveData);
      e.bulletsController.addListener(_saveData);
      setState(() => _workEntries.add(e));
      _saveData();
    } else {
      e.dispose();
    }
  }

  void _addEducationEntry() async {
    final e = PeriodEntry();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PeriodEntryDialog(entry: e),
    );

    if (result != null) {
      e.titleController.text = result['title'];
      e.companyController.text = result['company'] ?? '';
      e.startMonth = result['startMonth'];
      e.startYearController.text = result['startYear'];
      e.isPresent = result['isPresent'];
      e.endMonth = result['endMonth'];
      e.endYearController.text = result['endYear'];
      e.pdfPath = result['pdfPath'];
      e.bulletPoints = (result['bullets'] as List<String>?) ?? [];
      e.bulletsController.text = e.bulletPoints.join('\n');
      e.titleController.addListener(_saveData);
      e.companyController.addListener(_saveData);
      e.bulletsController.addListener(_saveData);
      setState(() => _educationEntries.add(e));
      _saveData();
    } else {
      e.dispose();
    }
  }

  void _addSkillEntry() async {
    final section = SkillSection();
    final titleResult = await showDialog<String?>(
      context: context,
      builder: (context) => _buildSectionDialog(),
    );

    if (titleResult != null && titleResult.isNotEmpty) {
      section.titleController.text = titleResult;
      section.skills.add(SkillEntry());
      section.titleController.addListener(_saveData);
      for (final skill in section.skills) {
        skill.nameController.addListener(_saveData);
      }
      setState(() => _skillSections.add(section));
      _saveData();
    } else {
      section.dispose();
    }
  }

  void _addSkillToSection(SkillSection section) {
    final skill = SkillEntry();
    skill.nameController.addListener(_saveData);
    setState(() => section.skills.add(skill));
    _saveData();
  }

  void _removeSkillFromSection(SkillSection section, int skillIndex) {
    if (section.skills.length <= 1) return;
    final skill = section.skills.removeAt(skillIndex);
    skill.dispose();
    setState(() {});
    _saveData();
  }

  void _removeSectionEntry(int index) {
    if (_skillSections.length <= 1) return;
    final section = _skillSections.removeAt(index);
    section.dispose();
    setState(() {});
    _saveData();
  }

  Widget _buildSectionDialog() {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('New Skill Section'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Section Title',
          hintText: 'e.g. Programming Languages, Developer Tools',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _onLanguageChanged(LanguageEntry entry) {
    if (_languageEntries.isNotEmpty && _languageEntries.last == entry) {
      final text = entry.nameController.text;
      if (text.trim().isNotEmpty) {
        _addLanguageEntry();
      }
    }
    _saveData();
  }

  void _addLanguageEntry() {
    final e = LanguageEntry();
    e.nameController.addListener(() => _onLanguageChanged(e));
    setState(() => _languageEntries.add(e));
    _saveData();
  }

  Future<void> _addLanguageEntryWithDialog() async {
    final e = LanguageEntry();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LanguageEntryDialog(entry: e),
    );

    if (result != null) {
      e.nameController.text = result['name'];
      e.level = result['level'];
      e.certificatePath = result['certificatePath'];
      e.nameController.addListener(() => _onLanguageChanged(e));
      setState(() => _languageEntries.add(e));
      _saveData();
    } else {
      e.dispose();
    }
  }

  Future<void> _showEditLanguageDialog(int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LanguageEntryDialog(entry: _languageEntries[index]),
    );

    if (result != null) {
      setState(() {
        _languageEntries[index].nameController.text = result['name'];
        _languageEntries[index].level = result['level'];
        _languageEntries[index].certificatePath = result['certificatePath'];
      });
      _saveData();
    }
  }

  Future<void> _addProfileLink() async {
    final link = ProfileLink();
    final result = await _showProfileLinkDialog(link);

    if (result != null) {
      link.labelController.text = result['label'] ?? '';
      link.urlController.text = result['url'] ?? '';
      link.labelController.addListener(_saveData);
      link.urlController.addListener(_saveData);
      setState(() => _profileLinks.add(link));
      _saveData();
    } else {
      link.dispose();
    }
  }

  Future<void> _editProfileLink(int index) async {
    final result = await _showProfileLinkDialog(_profileLinks[index]);

    if (result != null) {
      setState(() {
        _profileLinks[index].labelController.text = result['label'] ?? '';
        _profileLinks[index].urlController.text = result['url'] ?? '';
      });
      _saveData();
    }
  }

  void _removeProfileLink(int index) {
    final link = _profileLinks.removeAt(index);
    link.dispose();
    setState(() {});
    _saveData();
  }

  Future<Map<String, String>?> _showProfileLinkDialog(ProfileLink link) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ProfileLinkDialog(
        initialLabel: link.labelController.text,
        initialUrl: link.urlController.text,
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) {
        setState(() {
          _resumeProvider.personalData.profileImageBytes = bytes;
        });
        _saveData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read image data. Please try a PNG or JPEG.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showEditPeriodDialog(List<PeriodEntry> list, int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PeriodEntryDialog(entry: list[index]),
    );

    if (result != null) {
      setState(() {
        list[index].titleController.text = result['title'];
        list[index].companyController.text = result['company'] ?? '';
        list[index].startMonth = result['startMonth'];
        list[index].startYearController.text = result['startYear'];
        list[index].isPresent = result['isPresent'];
        list[index].endMonth = result['endMonth'];
        list[index].endYearController.text = result['endYear'];
        list[index].pdfPath = result['pdfPath'];
        list[index].bulletPoints = (result['bullets'] as List<String>?) ?? [];
        list[index].bulletsController.text = list[index].bulletPoints.join(
          '\n',
        );
      });
      _saveData();
    }
  }

  void _removeLanguageEntry(int index) {
    final e = _languageEntries.removeAt(index);
    e.dispose();
    setState(() {});
    _saveData();
  }

  Future<void> _onExportPressed() async {
    await _downloadResumePdf();
  }

  Future<void> _onExportCoverLetterPressed() async {
    await _downloadCoverLetterPdf();
  }

  Future<void> _shareApplicationPackage() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package sharing is not supported on web yet.'),
          ),
        );
      }
      return;
    }

    if (!_validatePackageData()) return;

    setState(() {
      _isExportingPackage = true;
      _packageExportState = ExportVisualState.loading;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final packageDir = await Directory(
        '${tempDir.path}${Platform.pathSeparator}application_package_${DateTime.now().millisecondsSinceEpoch}',
      ).create(recursive: true);

      final pdfPaths = <String>[];
      final coverLetterData = await _tryLoadCoverLetterData();
      
      // 1. Cover letter first
      if (coverLetterData != null) {
        final coverLetterBytes = await _generateCoverLetterPdf(coverLetterData);
        final (firstName, lastName) = _parseFullName();
        final coverLetterName = CoverLetterPdfService.buildFileName(
          firstName,
          lastName,
        );
        final coverLetterPath =
            '${packageDir.path}${Platform.pathSeparator}$coverLetterName';
        await _savePdfToFile(
          coverLetterBytes,
          packageDir.path,
          coverLetterName,
        );
        pdfPaths.add(coverLetterPath);
      }

      // 2. Resume second
      final resumeBytes = await _generateResumePdf();
      final resumeName = ResumePdfService.exportFileName(
        _resumeProvider.personalData.fullName,
      );
      final resumePath =
          '${packageDir.path}${Platform.pathSeparator}$resumeName';
      await _savePdfToFile(resumeBytes, packageDir.path, resumeName);
      pdfPaths.add(resumePath);

      // 3. Certificates in order of entries
      final copiedDocs = await _copySupportingDocs(packageDir.path);
      pdfPaths.addAll(copiedDocs);

      final pdfOnly =
          pdfPaths.where((p) => p.toLowerCase().endsWith('.pdf')).toList();
      if (pdfOnly.isEmpty) {
        throw Exception('No PDF files available to merge');
      }

      // Merge all PDFs into one
      final mergedBytes = await _mergePdfs(pdfOnly);
      final mergedFileName = 'Application_Package_${_resumeProvider.personalData.fullName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      final mergedPath =
          '${packageDir.path}${Platform.pathSeparator}$mergedFileName';
      await File(mergedPath).writeAsBytes(mergedBytes);

      final displayName =
          _resumeProvider.personalData.fullName.isNotEmpty
              ? _resumeProvider.personalData.fullName
              : 'application package';

      await Share.shareXFiles(
        [XFile(mergedPath)],
        text: 'Application package for $displayName',
      );

      try {
        await packageDir.delete(recursive: true);
      } catch (_) {
        // Best-effort cleanup of temporary share directory
      }

      if (!mounted) return;
      setState(() => _packageExportState = ExportVisualState.success);
    } catch (e) {
      _handleExportError(
        'Failed to share package: $e',
        () => _packageExportState = ExportVisualState.error,
      );
    } finally {
      _finishExport(() => _isExportingPackage = false);
    }
  }

  Future<CoverLetterData?> _tryLoadCoverLetterData() async {
    try {
      final loadedData = await CoverLetterService.loadCoverLetterData();
      if (loadedData.coverLetterController.text.trim().isNotEmpty) {
        return loadedData;
      }
    } catch (_) {
      // Silently ignore if cover letter cannot be loaded
    }
    return null;
  }

  Future<void> _savePdfToFile(
    List<int> bytes,
    String directory,
    String filename,
  ) async {
    final path = '$directory${Platform.pathSeparator}$filename';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List> _generateResumePdf() async {
    return ResumePdfService.generatePdfBytes(
      personalData: _resumeProvider.personalData,
      workEntries: _workEntries,
      educationEntries: _educationEntries,
      skillSections: _skillSections,
      languageEntries: _languageEntries,
      profileLinks: _profileLinks,
    );
  }

  Future<Uint8List> _generateCoverLetterPdf(
    CoverLetterData coverLetterData,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildCoverLetterHeader(
                _resumeProvider.personalData.firstNameController.text.trim(),
                _resumeProvider.personalData.emailController.text.trim(),
                _resumeProvider.personalData.phoneController.text.trim(),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                _getCurrentDate(),
                style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
              ),

              pw.SizedBox(height: 10),

              if (coverLetterData.companyController.text.trim().isNotEmpty) ...[
                pw.Text(
                  'Hiring Manager',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(coverLetterData.companyController.text.trim()),
                pw.SizedBox(height: 10),
              ],

              pw.Text('Dear Hiring Manager,'),

              pw.SizedBox(height: 10),

              pw.Text(
                _sanitizeCoverLetterText(
                  coverLetterData.coverLetterController.text,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                _resumeProvider.personalData.firstNameController.text.trim(),
              ),

              if (_resumeProvider.personalData.emailController.text
                  .trim()
                  .isNotEmpty)
                pw.Text(
                  'Email: ${_resumeProvider.personalData.emailController.text.trim()}',
                ),
              if (_resumeProvider.personalData.phoneController.text
                  .trim()
                  .isNotEmpty)
                pw.Text(
                  'Phone: ${_resumeProvider.personalData.phoneController.text.trim()}',
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Helper methods for PDF generation (same as in ApplicationPackageService)
  static pw.Widget _buildCoverLetterHeader(
    String firstName,
    String email,
    String phone,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          firstName,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF2C3E50),
          ),
        ),
        if (email.isNotEmpty || phone.isNotEmpty)
          pw.Text(
            [email, phone].where((s) => s.isNotEmpty).join(' | '),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
      ],
    );
  }

  Future<void> _onExportPackagePressed() async {
    await _shareApplicationPackage();
  }

  Future<Uint8List> _mergePdfs(List<String> pdfPaths) async {
    final mergedDoc = pw.Document();

    for (final pdfPath in pdfPaths) {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      
      // For each PDF, render pages as images and add to merged document
      try {
        await for (final page in Printing.raster(
          bytes,
          pages: List.generate(100, (i) => i), // Attempt first 100 pages
          dpi: 300, // High resolution for better quality
        )) {
          final imageBytes = await page.toPng();
          final image = pw.MemoryImage(imageBytes);
          mergedDoc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (context) => pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (_) {
        // Skip PDFs that can't be processed
      }
    }

    return mergedDoc.save();
  }

  Future<List<String>> _copySupportingDocs(String directory) async {
    final copiedPaths = <String>[];

    for (final entry in _workEntries) {
      final copiedPath = await _copyIfExists(entry.pdfPath, directory);
      if (copiedPath != null) copiedPaths.add(copiedPath);
    }
    for (final entry in _educationEntries) {
      final copiedPath = await _copyIfExists(entry.pdfPath, directory);
      if (copiedPath != null) copiedPaths.add(copiedPath);
    }
    for (final section in _skillSections) {
      for (final skill in section.skills) {
        final copiedPath = await _copyIfExists(skill.certificatePath, directory);
        if (copiedPath != null) copiedPaths.add(copiedPath);
      }
    }
    for (final lang in _languageEntries) {
      final copiedPath = await _copyIfExists(lang.certificatePath, directory);
      if (copiedPath != null) copiedPaths.add(copiedPath);
    }

    return copiedPaths;
  }

  Future<String?> _copyIfExists(String? sourcePath, String directory) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;
    if (!sourcePath.toLowerCase().endsWith('.pdf')) return null;
    final file = File(sourcePath);
    if (!await file.exists()) return null;

    final name = _fileNameFromPath(sourcePath);
    final destPath = '$directory${Platform.pathSeparator}$name';
    await file.copy(destPath);
    return destPath;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? 'document.pdf' : parts.last;
  }

  void _scheduleExportStateReset() {
    _exportStateResetTimer?.cancel();
    _exportStateResetTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _exportState = ExportVisualState.idle;
        _coverLetterExportState = ExportVisualState.idle;
        _packageExportState = ExportVisualState.idle;
      });
    });
  }

  Future<void> _downloadResumePdf() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF export is not supported on web.')),
        );
      }
      return;
    }
    setState(() {
      _isExporting = true;
      _exportState = ExportVisualState.loading;
    });

    try {
      final pdfBytes = await _generateResumePdf();
      final filename = ResumePdfService.exportFileName(
        _resumeProvider.personalData.fullName,
      );
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);

      if (!mounted) return;
      setState(() => _exportState = ExportVisualState.success);
    } catch (e) {
      _handleExportError(
        'Failed to export resume: $e',
        () => _exportState = ExportVisualState.error,
      );
    } finally {
      _finishExport(() => _isExporting = false);
    }
  }

  Future<void> _downloadCoverLetterPdf() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF export is not supported on web.')),
        );
      }
      return;
    }
    setState(() {
      _isExportingCoverLetter = true;
      _coverLetterExportState = ExportVisualState.loading;
    });

    try {
      final coverLetterData = await CoverLetterService.loadCoverLetterData();
      if (coverLetterData.coverLetterController.text.trim().isEmpty) {
        throw Exception('Cover letter is empty');
      }

      final pdfBytes = await _generateCoverLetterPdf(coverLetterData);
      final (firstName, lastName) = _parseFullName();
      final filename = CoverLetterPdfService.buildFileName(firstName, lastName);
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);

      if (!mounted) return;
      setState(() => _coverLetterExportState = ExportVisualState.success);
    } catch (e) {
      _handleExportError(
        'Failed to export cover letter: $e',
        () => _coverLetterExportState = ExportVisualState.error,
      );
    } finally {
      _finishExport(() => _isExportingCoverLetter = false);
    }
  }

  String _periodLabel(PeriodEntry e) => ResumePdfService.periodLabel(e);

  List<PeriodEntry> _sortedPeriodEntries(List<PeriodEntry> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      // Present entries first
      if (a.isPresent && !b.isPresent) return -1;
      if (!a.isPresent && b.isPresent) return 1;

      // If both are present or both are not present, sort by end year/month
      if (a.isPresent && b.isPresent) {
        // Both present, no specific order needed
        return 0;
      }

      // Both are not present, sort by end date (most recent first)
      final aEndYear = int.tryParse(a.endYearController.text) ?? 0;
      final bEndYear = int.tryParse(b.endYearController.text) ?? 0;

      if (aEndYear != bEndYear) {
        return bEndYear.compareTo(aEndYear);
      }

      // Same year, sort by month
      final monthOrder = {
        'January': 1,
        'February': 2,
        'March': 3,
        'April': 4,
        'May': 5,
        'June': 6,
        'July': 7,
        'August': 8,
        'September': 9,
        'October': 10,
        'November': 11,
        'December': 12,
      };
      final aMonth = monthOrder[a.endMonth] ?? 0;
      final bMonth = monthOrder[b.endMonth] ?? 0;

      return bMonth.compareTo(aMonth);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProfileHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(children: [_buildSectionFrame()]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final fullName = _resumeProvider.personalData.fullName;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickProfileImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6964EE),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9999),
                          image:
                              _resumeProvider.personalData.profileImageBytes !=
                                  null
                              ? DecorationImage(
                                  image: MemoryImage(
                                    _resumeProvider
                                        .personalData
                                        .profileImageBytes!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            _resumeProvider.personalData.profileImageBytes ==
                                null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey.shade300,
                              )
                            : null,
                      ),
                      if (_resumeProvider.personalData.profileImageBytes !=
                          null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Name
              Text(
                fullName.isEmpty ? 'Your Name' : fullName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildSectionFrame() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCollapsibleSection(
          title: 'Profile',
          icon: Icons.person,
          content: _buildEditProfileContent(),
          isExpanded: _isEditProfileExpanded,
          onToggle: () =>
              setState(() => _isEditProfileExpanded = !_isEditProfileExpanded),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          title: 'Work Experience',
          icon: Icons.work,
          content: _buildWorkExperienceContent(),
          isExpanded: _isWorkExperienceExpanded,
          onToggle: () => setState(
            () => _isWorkExperienceExpanded = !_isWorkExperienceExpanded,
          ),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          title: 'Education',
          icon: Icons.school,
          content: _buildEducationContent(),
          isExpanded: _isEducationExpanded,
          onToggle: () =>
              setState(() => _isEducationExpanded = !_isEducationExpanded),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          title: 'Skills',
          icon: Icons.extension,
          content: _buildSkillsContent(),
          isExpanded: _isSkillsExpanded,
          onToggle: () =>
              setState(() => _isSkillsExpanded = !_isSkillsExpanded),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          title: 'Languages',
          icon: Icons.language,
          content: _buildLanguagesContent(),
          isExpanded: _isLanguagesExpanded,
          onToggle: () =>
              setState(() => _isLanguagesExpanded = !_isLanguagesExpanded),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          title: 'Profile Links',
          icon: Icons.link,
          content: _buildProfileLinksContent(),
          isExpanded: _isProfileLinksExpanded,
          onToggle: () => setState(
            () => _isProfileLinksExpanded = !_isProfileLinksExpanded,
          ),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          title: 'Cover Letter Generator',
          icon: Icons.description,
          content: _buildCoverLetterContent(),
          isExpanded: _isCoverLetterExpanded,
          onToggle: () =>
              setState(() => _isCoverLetterExpanded = !_isCoverLetterExpanded),
          isDashed: true,
        ),
        const SizedBox(height: 16),
        _buildCollapsibleSection(
          title: 'Export',
          icon: Icons.download,
          content: _buildExportContent(),
          isExpanded: _isExportExpanded,
          onToggle: () =>
              setState(() => _isExportExpanded = !_isExportExpanded),
          isDashed: true,
        ),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Widget content,
    required bool isExpanded,
    required VoidCallback onToggle,
    bool isDashed = false,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(8),
                  border: isDashed
                      ? Border.all(color: const Color(0xFFB6B1AD), width: 1)
                      : Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? const Color(0xFF6964EE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Icon(
                        icon,
                        color: isExpanded
                            ? Colors.white
                            : const Color(0xFF9296AB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_downward,
                        color: isExpanded
                            ? const Color(0xFF6964EE)
                            : const Color(0xFF9296AB),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: content,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileInputField(
            'Full name',
            _resumeProvider.personalData.firstNameController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'Email',
            _resumeProvider.personalData.emailController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'Phone number',
            _resumeProvider.personalData.phoneController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'Birth date',
            _resumeProvider.personalData.birthDateController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'Postal code',
            _resumeProvider.personalData.postalCodeController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'City',
            _resumeProvider.personalData.cityController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'Street',
            _resumeProvider.personalData.streetController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'House number',
            _resumeProvider.personalData.houseNumberController,
          ),
          const SizedBox(height: 10),
          _buildProfileInputField(
            'Birth place',
            _resumeProvider.personalData.birthPlaceController,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInputField(
    String label,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 17,
            color: Color(0xFF9296AB),
          ),
          border: InputBorder.none,
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 4,
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildWorkExperienceContent() {
    final sortedEntries = _sortedPeriodEntries(_workEntries);
    return Column(
      children: [
        if (_workEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No work experience added yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: sortedEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final originalIndex = _workEntries.indexOf(entry);
              return _buildPeriodTile(_workEntries, originalIndex);
            },
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addWorkEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add entry'),
        ),
      ],
    );
  }

  Widget _buildEducationContent() {
    final sortedEntries = _sortedPeriodEntries(_educationEntries);
    return Column(
      children: [
        if (_educationEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No education added yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: sortedEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final originalIndex = _educationEntries.indexOf(entry);
              return _buildPeriodTile(_educationEntries, originalIndex);
            },
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addEducationEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add entry'),
        ),
      ],
    );
  }

  Widget _buildSkillsContent() {
    return Column(
      children: [
        if (_skillSections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No skills added yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _skillSections.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildSkillSectionTile(index),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addSkillEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add section'),
        ),
      ],
    );
  }

  Widget _buildLanguagesContent() {
    return Column(
      children: [
        if (_languageEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No languages added yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _languageEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildLanguageTile(index),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addLanguageEntryWithDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add language'),
        ),
      ],
    );
  }

  Widget _buildProfileLinksContent() {
    return Column(
      children: [
        if (_profileLinks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No profile links added yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _profileLinks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildProfileLinkTile(index),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addProfileLink,
          icon: const Icon(Icons.add),
          label: const Text('Add profile link'),
        ),
      ],
    );
  }

  Widget _buildCoverLetterContent() {
    return FutureBuilder<CoverLetterData>(
      future: CoverLetterService.loadCoverLetterData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final hasCoverLetter =
            snapshot.hasData &&
            snapshot.data!.coverLetterController.text.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate professional cover letters with AI assistance',
            ),
            const SizedBox(height: 8),
            if (hasCoverLetter) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cover letter available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF9296AB),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No cover letter generated yet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              '• Basic AI generator (free)',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              '• Uses your resume data',
              style: TextStyle(fontSize: 12),
            ),
            const Text('• Export as PDF', style: TextStyle(fontSize: 12)),
            const Text('• Editable content', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoverLetterScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Open Cover Letter Generator'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportContent() {
    return Column(
      children: [
        // Resume PDF Export
        _buildExportTile(
          title: 'Resume PDF Only',
          subtitle: _getExportSubtitle(),
          icon: Icons.description,
          state: _exportState,
          isExporting: _isExporting,
          onPressed: _onExportPressed,
        ),
        const SizedBox(height: 12),
        // Cover Letter PDF Export
        _buildExportTile(
          title: 'Cover Letter PDF Only',
          subtitle: 'Save your cover letter as a PDF',
          icon: Icons.mail_outline,
          state: _coverLetterExportState,
          isExporting: _isExportingCoverLetter,
          onPressed: _onExportCoverLetterPressed,
        ),
        const SizedBox(height: 12),
        // Complete Package Export
        FutureBuilder<CoverLetterData>(
          future: CoverLetterService.loadCoverLetterData(),
          builder: (context, snapshot) {
            final hasCoverLetter =
                snapshot.hasData &&
                snapshot.data!.coverLetterController.text.trim().isNotEmpty;

            // Count documents
            int docCount = 0;
            for (final entry in _workEntries) {
              if (entry.pdfPath != null && entry.pdfPath!.isNotEmpty) {
                docCount++;
              }
            }
            for (final entry in _educationEntries) {
              if (entry.pdfPath != null && entry.pdfPath!.isNotEmpty) {
                docCount++;
              }
            }
            for (final section in _skillSections) {
              for (final skill in section.skills) {
                if (skill.certificatePath != null &&
                    skill.certificatePath!.isNotEmpty) {
                  docCount++;
                }
              }
            }
            for (final lang in _languageEntries) {
              if (lang.certificatePath != null &&
                  lang.certificatePath!.isNotEmpty) {
                docCount++;
              }
            }

            return Column(
              children: [
                _buildExportTile(
                  title: 'Complete Application Package',
                  subtitle: _getPackageExportSubtitle(),
                  icon: Icons.folder_zip,
                  state: _packageExportState,
                  isExporting: _isExportingPackage,
                  onPressed: _onExportPackagePressed,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildInfoChip('Resume PDF', true),
                    _buildInfoChip('Cover Letter', hasCoverLetter),
                    _buildInfoChip(
                      '$docCount Document${docCount != 1 ? 's' : ''}',
                      docCount > 0,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required ExportVisualState state,
    required bool isExporting,
    required VoidCallback onPressed,
  }) {
    Color tileColor;
    Color borderColor;
    switch (state) {
      case ExportVisualState.loading:
        tileColor = const Color(0xFFEEF2FF);
        borderColor = const Color(0xFF6964EE);
        break;
      case ExportVisualState.success:
        tileColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        break;
      case ExportVisualState.error:
        tileColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        break;
      case ExportVisualState.idle:
        tileColor = Colors.white;
        borderColor = const Color(0xFFB6B1AD);
    }

    Widget trailing;
    if (isExporting) {
      trailing = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey.shade500,
        ),
      );
    } else if (state == ExportVisualState.success) {
      trailing = const Icon(Icons.check_circle, color: Colors.green, size: 22);
    } else if (state == ExportVisualState.error) {
      trailing = const Icon(Icons.error_outline, color: Colors.red, size: 22);
    } else {
      trailing = const Icon(Icons.download, color: Color(0xFF9296AB), size: 20);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isExporting ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(8),
            color: tileColor,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Icon(icon, color: const Color(0xFF9296AB), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: _getSubtitleColor(state),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: IconButton(
                  key: ValueKey('$title-${state.toString()}-$isExporting'),
                  tooltip: title,
                  onPressed: isExporting ? null : onPressed,
                  icon: trailing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, bool hasContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasContent ? Colors.green.shade50 : const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasContent ? Colors.green.shade300 : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasContent)
            const Icon(Icons.check_circle, color: Colors.green, size: 12)
          else
            const Icon(Icons.cancel, color: Colors.grey, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: hasContent
                  ? Colors.green.shade800
                  : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  String _getExportSubtitle() {
    switch (_exportState) {
      case ExportVisualState.loading:
        return 'Exporting…';
      case ExportVisualState.success:
        return 'Saved successfully';
      case ExportVisualState.error:
        return 'Export failed';
      case ExportVisualState.idle:
        return 'PDF only';
    }
  }

  String _getPackageExportSubtitle() {
    switch (_packageExportState) {
      case ExportVisualState.loading:
        return 'Creating package…';
      case ExportVisualState.success:
        return 'Package shared';
      case ExportVisualState.error:
        return 'Export failed';
      case ExportVisualState.idle:
        return 'PDF + documents';
    }
  }

  Color _getSubtitleColor(ExportVisualState state) {
    switch (state) {
      case ExportVisualState.loading:
        return Colors.grey.shade700;
      case ExportVisualState.success:
        return Colors.green.shade700;
      case ExportVisualState.error:
        return Colors.red.shade700;
      case ExportVisualState.idle:
        return Colors.grey.shade600;
    }
  }

  Widget _buildPeriodTile(List<PeriodEntry> list, int index) {
    final e = list[index];
    final titleText = e.titleController.text.trim().isEmpty
        ? 'New entry'
        : e.titleController.text.trim();
    final hasPdf = e.pdfPath != null && e.pdfPath!.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        title: Row(
          children: [
            Expanded(child: Text(titleText)),
            if (hasPdf)
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
          ],
        ),
        subtitle: Text(_periodLabel(e), style: const TextStyle(fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditPeriodDialog(list, index),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                final e = list.removeAt(index);
                e.dispose();
                setState(() {});
                _saveData();
              },
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _showEditPeriodDialog(list, index),
      ),
    );
  }

  // Note: Unused - kept for future extension
  // Note: Unused - kept for future extension
  // ignore: unused_element
  Widget _buildSkillTile(int index) {
    return const SizedBox.shrink();
  }

  Widget _buildSkillSectionTile(int index) {
    final section = _skillSections[index];
    final sectionTitle = section.titleController.text.trim().isEmpty
        ? 'New Section'
        : section.titleController.text.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sectionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeSectionEntry(index),
                  tooltip: 'Delete section',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: section.skills.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 4),
              itemBuilder: (context, idx) => _buildSkillItemTile(section, idx),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addSkillToSection(section),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add skill'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillItemTile(SkillSection section, int skillIndex) {
    final skill = section.skills[skillIndex];
    final skillName = skill.nameController.text.trim().isEmpty
        ? 'New skill'
        : skill.nameController.text.trim();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      title: Text(skillName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _showEditSkillDialog(section, skillIndex),
            tooltip: 'Edit skill',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _removeSkillFromSection(section, skillIndex),
            tooltip: 'Delete skill',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSkillDialog(
    SkillSection section,
    int skillIndex,
  ) async {
    final skill = section.skills[skillIndex];
    final controller = TextEditingController(
      text: skill.nameController.text.trim(),
    );

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit skill'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Skill name',
            hintText: 'e.g. C++, Python, JavaScript',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() => skill.nameController.text = result.trim());
      _saveData();
    }
  }

  Widget _buildLanguageTile(int index) {
    final e = _languageEntries[index];
    final languageName = e.nameController.text.trim().isEmpty
        ? 'New language'
        : e.nameController.text.trim();
    final hasCertificate =
        e.certificatePath != null && e.certificatePath!.isNotEmpty;
    final level = e.level;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        title: Row(
          children: [
            Expanded(child: Text(languageName)),
            if (hasCertificate)
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
          ],
        ),
        subtitle: level != null
            ? Text(level, style: const TextStyle(fontSize: 13))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditLanguageDialog(index),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeLanguageEntry(index),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _showEditLanguageDialog(index),
      ),
    );
  }

  Widget _buildProfileLinkTile(int index) {
    final link = _profileLinks[index];
    final label = link.labelController.text.trim().isEmpty
        ? 'New link'
        : link.labelController.text.trim();
    final url = link.urlController.text.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        leading: const Icon(Icons.link, color: Color(0xFF6964EE)),
        title: Text(label),
        subtitle: url.isNotEmpty
            ? Text(
                url,
                style: const TextStyle(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editProfileLink(index),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeProfileLink(index),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _editProfileLink(index),
      ),
    );
  }
}

/// Dialog for adding/editing profile links
class _ProfileLinkDialog extends StatefulWidget {
  final String initialLabel;
  final String initialUrl;

  const _ProfileLinkDialog({
    required this.initialLabel,
    required this.initialUrl,
  });

  @override
  State<_ProfileLinkDialog> createState() => _ProfileLinkDialogState();
}

class _ProfileLinkDialogState extends State<_ProfileLinkDialog> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initialLabel);
    _urlCtrl = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profile Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. LinkedIn, GitHub, Portfolio',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'e.g. https://linkedin.com/in/username',
            ),
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'label': _labelCtrl.text,
              'url': _urlCtrl.text,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
