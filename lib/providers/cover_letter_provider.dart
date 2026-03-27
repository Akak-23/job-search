import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cover_letter_data.dart';
import '../services/cover_letter_service.dart';
import '../services/resume_data_service.dart';

class CoverLetterProvider extends ChangeNotifier {
  late CoverLetterData _coverLetterData;
  bool isLoading = false;
  bool isExporting = false;
  String? error;
  String? successMessage;

  CoverLetterProvider() {
    _coverLetterData = CoverLetterData();
  }

  static String _sanitizeCoverLetterText(String text) {
    return text
        .replaceAll('•', '-')
        .replaceAll('▪', '-')
        .replaceAll('◦', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('Sincerely,', '')
        .replaceAll('Sincerely', '');
  }

  CoverLetterData get coverLetterData => _coverLetterData;

  Future<void> loadCoverLetterData() async {
    isLoading = true;
    error = null;
    successMessage = null;
    notifyListeners();

    try {
      final data = await CoverLetterService.loadCoverLetterData();

      // Preserve existing controllers to keep listeners intact
      _coverLetterData.coverLetterController.text =
          data.coverLetterController.text;
      _coverLetterData.selectedProvider = data.selectedProvider;
      _coverLetterData.apiKey = data.apiKey;
      _coverLetterData.customInstructions = data.customInstructions;

      error = null;
    } catch (err) {
      error = err.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveCoverLetterData({bool silent = false}) async {
    try {
      await CoverLetterService.saveCoverLetterData(_coverLetterData);
      error = null;
      successMessage = silent ? null : 'Cover letter data saved successfully!';
    } catch (err) {
      error = err.toString();
      successMessage = null;
    }

    // Still notify to propagate errors/updates, but avoid noisy success banners when silent
    notifyListeners();
  }

  Future<void> generateCoverLetter() async {
    isLoading = true;
    error = null;
    successMessage = null;
    notifyListeners();

    try {
      // Validate required fields
      if (_coverLetterData.jobTitleController.text.trim().isEmpty) {
        throw Exception('Please enter a job title');
      }
      if (_coverLetterData.companyController.text.trim().isEmpty) {
        throw Exception('Please enter a company name');
      }

      final generatedText = await CoverLetterService.generateCoverLetter(
        provider: _coverLetterData.selectedProvider,
        jobTitle: _coverLetterData.jobTitleController.text.trim(),
        company: _coverLetterData.companyController.text.trim(),
        requirements: _coverLetterData.requirementsController.text.trim(),
        experience: _coverLetterData.experienceController.text.trim(),
        apiKey: _coverLetterData.apiKey,
        customInstructions: _coverLetterData.customInstructions,
        jobDescription: _coverLetterData.jobDescriptionController.text.trim(),
        firstName: _coverLetterData.firstName,
        lastName: _coverLetterData.lastName,
        email: _coverLetterData.email,
        phone: _coverLetterData.phone,
        skills: _coverLetterData.skills,
        workExperience: _coverLetterData.workExperience,
        education: _coverLetterData.education,
      );
      
      _coverLetterData.coverLetterController.text = generatedText;
      error = null;
      successMessage = 'Cover letter generated successfully!';
    } catch (err) {
      error = err.toString();
      successMessage = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setProvider(String provider) {
    _coverLetterData.selectedProvider = provider;
    notifyListeners();
  }

  void setApiKey(String key) {
    _coverLetterData.apiKey = key;
    notifyListeners();
  }

  void setCustomInstructions(String instructions) {
    _coverLetterData.customInstructions = instructions;
    notifyListeners();
  }

  void clearMessages() {
    error = null;
    successMessage = null;
    notifyListeners();
  }

  List<String> getAvailableProviders() {
    return CoverLetterService.getAvailableProviders();
  }

  String getProviderDisplayName(String provider) {
    return CoverLetterService.getProviderDisplayName(provider);
  }

  String getProviderDescription(String provider) {
    return CoverLetterService.getProviderDescription(provider);
  }

  void populateFromResume({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required List<String> skills,
    required List<Map<String, dynamic>> workExperience,
    required List<Map<String, dynamic>> education,
  }) {
    _coverLetterData.firstName = firstName;
    _coverLetterData.lastName = lastName;
    _coverLetterData.email = email;
    _coverLetterData.phone = phone;
    _coverLetterData.skills = skills;
    _coverLetterData.workExperience = workExperience;
    _coverLetterData.education = education;
    notifyListeners();
  }

  void setJobDescription(String description) {
    _coverLetterData.jobDescriptionController.text = description;
    notifyListeners();
  }

  Future<void> loadResumeData() async {
    try {
      // Load personal data
      final personalData = await ResumeDataService.loadPersonalData();
      _coverLetterData.firstName = personalData.firstNameController.text;
      // Extract last name from full name if available, or leave empty
      _coverLetterData.lastName = ''; // ResumeData doesn't have separate last name
      _coverLetterData.email = personalData.emailController.text;
      _coverLetterData.phone = personalData.phoneController.text;

      // Load work experience
      final workEntries = await ResumeDataService.loadWorkEntries();
      _coverLetterData.workExperience = workEntries
          .where((e) => e.titleController.text.trim().isNotEmpty)
          .map((e) => {
                'title': e.titleController.text,
                'company': e.companyController.text,
                'description': e.bulletsController.text,
                'period': '${e.startMonth ?? ''} ${e.startYearController.text} - ${e.isPresent ? 'Present' : '${e.endMonth ?? ''} ${e.endYearController.text}'}',
              })
          .toList();

      // Load skills
      final skillSections = await ResumeDataService.loadSkillSections();
      final allSkills = <String>[];
      for (final section in skillSections) {
        for (final skill in section.skills) {
          if (skill.nameController.text.trim().isNotEmpty) {
            allSkills.add(skill.nameController.text.trim());
          }
        }
      }
      _coverLetterData.skills = allSkills;

      // Load education
      final educationEntries = await ResumeDataService.loadEducationEntries();
      _coverLetterData.education = educationEntries
          .where((e) => e.titleController.text.trim().isNotEmpty)
          .map((e) => {
                'degree': e.titleController.text,
                'institution': e.companyController.text,
                'description': e.bulletsController.text,
                'period': '${e.startMonth ?? ''} ${e.startYearController.text} - ${e.isPresent ? 'Present' : '${e.endMonth ?? ''} ${e.endYearController.text}'}',
              })
          .toList();

      notifyListeners();
    } catch (err) {
      error = 'Failed to load resume data: ${err.toString()}';
      notifyListeners();
    }
  }

  Future<void> shareCoverLetter() async {
    isExporting = true;
    error = null;
    successMessage = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        throw UnsupportedError('PDF export is not supported on web.');
      }
      if (_coverLetterData.coverLetterController.text.trim().isEmpty) {
        throw Exception('Cover letter content is empty. Please generate or write a cover letter first.');
      }

      // Generate PDF in memory
      final pdfBytes = await _generateCoverLetterPdf();
      
      // Create temp file
      final tempFile = await _createTempFile(pdfBytes, 'cover_letter.pdf');
      
      // Share directly
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Cover Letter PDF');
      
      // Clean up temp file
      await tempFile.delete();
      
      successMessage = 'Cover letter shared successfully!';
    } catch (err) {
      error = err.toString();
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<Uint8List> _generateCoverLetterPdf() async {
    final pdf = pw.Document();

    final sanitizedBody = _sanitizeCoverLetterText(
      _coverLetterData.coverLetterController.text,
    ).trim();
    final paragraphs = _splitIntoParagraphs(sanitizedBody);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with contact info - plain text only
              pw.Text(
                '${ _coverLetterData.firstName} ${ _coverLetterData.lastName}'.trim(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              if (_coverLetterData.email.isNotEmpty)
                pw.Text(
                  _coverLetterData.email,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (_coverLetterData.phone.isNotEmpty)
                pw.Text(
                  _coverLetterData.phone,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              pw.SizedBox(height: 14),
              // Date
              pw.Text(
                _getCurrentDate(),
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 14),
              // Salutation
              pw.Text(
                'To whom it may concern,',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 12),
              // Body paragraphs
              _buildBodyTextOnly(paragraphs),
              pw.SizedBox(height: 14),
              // Closing - plain text only
              pw.Text(
                'Sincerely,',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                '${ _coverLetterData.firstName} ${ _coverLetterData.lastName}'.trim(),
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 24),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static List<String> _splitIntoParagraphs(String text) {
    final normalized = text.replaceAll('\r\n', '\n');
    final parts = normalized
        .split(RegExp(r'\n{2,}'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty && text.isNotEmpty) {
      return [text];
    }

    return parts;
  }

  Future<File> _createTempFile(Uint8List bytes, String filename) async {
    final tempDir = await getApplicationDocumentsDirectory();
    final tempFile = File('${tempDir.path}/$filename');
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile;
  }

  static pw.Widget _buildBodyTextOnly(List<String> paragraphs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 11),
            child: pw.Text(
              paragraph,
              style: const pw.TextStyle(
                fontSize: 11,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
      ],
    );
  }

  static String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  void dispose() {
    _coverLetterData.dispose();
    super.dispose();
  }
}
