import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/period_entry.dart';
import '../models/skill_section.dart';
import '../models/language_entry.dart';
import '../models/profile_link.dart';
import '../models/resume_data.dart';
import '../models/cover_letter_data.dart';
import 'resume_pdf_service.dart';

/// Service for creating complete application packages
class ApplicationPackageService {
  /// Creates a folder containing resume PDF, cover letter PDF, and all uploaded documents
  static Future<String> createApplicationPackage({
    required ResumeData personalData,
    required List<PeriodEntry> workEntries,
    required List<PeriodEntry> educationEntries,
    required List<SkillSection> skillSections,
    required List<LanguageEntry> languageEntries,
    required List<ProfileLink> profileLinks,
    required CoverLetterData? coverLetterData,
  }) async {
    // Create a timestamp for unique folder name
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fullName = personalData.fullName.isNotEmpty 
        ? personalData.fullName.replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '')
        : 'Candidate';
    
    // Get base directory - use Downloads folder on Android
    Directory baseDir;
    if (Platform.isAndroid) {
      try {
        final Directory? downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir != null) {
          baseDir = downloadsDir;
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    
    final packageDir = Directory('${baseDir.path}${Platform.pathSeparator}Application_Package_${fullName}_$timestamp');
    
    // Create the package directory
    if (!await packageDir.exists()) {
      await packageDir.create(recursive: true);
    }

    // 1. Generate and save resume PDF
    final resumeBytes = await _generateResumePdf(
      personalData: personalData,
      workEntries: workEntries,
      educationEntries: educationEntries,
      skillSections: skillSections,
      languageEntries: languageEntries,
      profileLinks: profileLinks,
    );
    final resumeFilename = _sanitizeFilename('Resume_$fullName.pdf');
    final resumeFile = File('${packageDir.path}${Platform.pathSeparator}$resumeFilename');
    await resumeFile.writeAsBytes(resumeBytes, flush: true);

    // 2. Generate and save cover letter PDF if available
    if (coverLetterData != null && coverLetterData.coverLetterController.text.trim().isNotEmpty) {
      final coverLetterBytes = await _generateCoverLetterPdf(
        coverLetterData: coverLetterData,
        personalData: personalData,
      );
      final coverLetterFilename = _sanitizeFilename('Cover_Letter_$fullName.pdf');
      final coverLetterFile = File('${packageDir.path}${Platform.pathSeparator}$coverLetterFilename');
      await coverLetterFile.writeAsBytes(coverLetterBytes, flush: true);
    }

    // 3. Create subfolders for different document types
    final documentsDir = Directory('${packageDir.path}${Platform.pathSeparator}Documents');
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }

    // 4. Copy all uploaded documents
    await _copyAllDocuments(
      documentsDir: documentsDir,
      workEntries: workEntries,
      educationEntries: educationEntries,
      skillSections: skillSections,
      languageEntries: languageEntries,
    );

    return packageDir.path;
  }

  /// Generate resume PDF as bytes
  static Future<Uint8List> _generateResumePdf({
    required ResumeData personalData,
    required List<PeriodEntry> workEntries,
    required List<PeriodEntry> educationEntries,
    required List<SkillSection> skillSections,
    required List<LanguageEntry> languageEntries,
    required List<ProfileLink> profileLinks,
  }) async {
    final doc = pw.Document();

    // Use the existing ResumePdfService logic but return bytes instead of saving
    final fullName = personalData.fullName;
    final birthDate = personalData.birthDateController.text.trim();
    final birthPlace = personalData.birthPlaceController.text.trim();
    final streetLine = personalData.streetLine;
    final cityLine = personalData.cityLine;

    // Get sorted entries
    final workEntriesSorted = ResumePdfService.sortedFilledPeriods(workEntries);
    final educationEntriesSorted = ResumePdfService.sortedFilledPeriods(educationEntries);
    final languages = languageEntries
        .where((e) => e.nameController.text.trim().isNotEmpty)
        .toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
          boldItalic: pw.Font.helveticaBoldOblique(),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeaderForPackage(personalData, fullName, streetLine, cityLine, profileLinks),
              pw.SizedBox(height: 18),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildLeftColumnForPackage(
                    personalData,
                    birthDate,
                    birthPlace,
                    languages,
                    skillSections,
                  ),
                  pw.SizedBox(width: 18),
                  _buildRightColumnForPackage(
                    workEntriesSorted,
                    educationEntriesSorted,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              _buildFooterForPackage(),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Generate cover letter PDF as bytes
  static Future<Uint8List> _generateCoverLetterPdf({
    required CoverLetterData coverLetterData,
    required ResumeData personalData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with candidate info
              _buildCoverLetterHeader(
                personalData.firstNameController.text.trim(),
                personalData.emailController.text.trim(),
                personalData.phoneController.text.trim(),
              ),
              
              pw.SizedBox(height: 20),
              
              // Date
              pw.Text(
                _getCurrentDate(),
                style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
              ),
              
              pw.SizedBox(height: 10),
              
              // Recipient info
              if (coverLetterData.companyController.text.trim().isNotEmpty) ...[
                pw.Text('Hiring Manager', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(coverLetterData.companyController.text.trim()),
                pw.SizedBox(height: 10),
              ],
              
              // Salutation
              pw.Text('Dear Hiring Manager,'),
              
              pw.SizedBox(height: 10),
              
              // Cover letter content
              pw.Text(
                coverLetterData.coverLetterController.text,
              ),
              
              pw.SizedBox(height: 20),
              
              // Closing
              pw.Text(personalData.firstNameController.text.trim()),
              
              if (personalData.emailController.text.trim().isNotEmpty) 
                pw.Text('Email: ${personalData.emailController.text.trim()}'),
              if (personalData.phoneController.text.trim().isNotEmpty) 
                pw.Text('Phone: ${personalData.phoneController.text.trim()}'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Copy all uploaded documents to the package folder
  static Future<void> _copyAllDocuments({
    required Directory documentsDir,
    required List<PeriodEntry> workEntries,
    required List<PeriodEntry> educationEntries,
    required List<SkillSection> skillSections,
    required List<LanguageEntry> languageEntries,
  }) async {
    // Copy work experience documents
    for (final entry in workEntries) {
      if (entry.pdfPath != null && entry.pdfPath!.isNotEmpty) {
        final sourceFile = File(entry.pdfPath!);
        if (await sourceFile.exists()) {
          final filename = _sanitizeFilename('Work_${entry.titleController.text}_${entry.companyController.text}.pdf');
          final destFile = File('${documentsDir.path}${Platform.pathSeparator}$filename');
          await destFile.writeAsBytes(await sourceFile.readAsBytes(), flush: true);
        }
      }
    }

    // Copy education documents
    for (final entry in educationEntries) {
      if (entry.pdfPath != null && entry.pdfPath!.isNotEmpty) {
        final sourceFile = File(entry.pdfPath!);
        if (await sourceFile.exists()) {
          final filename = _sanitizeFilename('Education_${entry.titleController.text}_${entry.companyController.text}.pdf');
          final destFile = File('${documentsDir.path}${Platform.pathSeparator}$filename');
          await destFile.writeAsBytes(await sourceFile.readAsBytes(), flush: true);
        }
      }
    }

    // Copy skill certificates
    for (final section in skillSections) {
      for (final skill in section.skills) {
        if (skill.certificatePath != null && skill.certificatePath!.isNotEmpty) {
          final sourceFile = File(skill.certificatePath!);
          if (await sourceFile.exists()) {
            final filename = _sanitizeFilename('Certificate_${skill.nameController.text}.pdf');
            final destFile = File('${documentsDir.path}${Platform.pathSeparator}$filename');
            await destFile.writeAsBytes(await sourceFile.readAsBytes(), flush: true);
          }
        }
      }
    }

    // Copy language certificates
    for (final language in languageEntries) {
      if (language.certificatePath != null && language.certificatePath!.isNotEmpty) {
        final sourceFile = File(language.certificatePath!);
        if (await sourceFile.exists()) {
          final filename = _sanitizeFilename('Language_${language.nameController.text}.pdf');
          final destFile = File('${documentsDir.path}${Platform.pathSeparator}$filename');
          await destFile.writeAsBytes(await sourceFile.readAsBytes(), flush: true);
        }
      }
    }
  }

  /// Helper method to build header for package PDF
  static pw.Widget _buildHeaderForPackage(
    ResumeData personalData,
    String fullName,
    String streetLine,
    String cityLine,
    List<ProfileLink> profileLinks,
  ) {
    final contactChips = <pw.Widget>[];
    if (personalData.emailController.text.trim().isNotEmpty) {
      contactChips.add(_chip('Email', personalData.emailController.text.trim()));
    }
    if (personalData.phoneController.text.trim().isNotEmpty) {
      contactChips.add(_chip('Phone', personalData.phoneController.text.trim()));
    }
    final addressLine = [streetLine, cityLine].where((s) => s.isNotEmpty).join(', ');
    if (addressLine.isNotEmpty) {
      contactChips.add(_chip('Address', addressLine));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    fullName.isEmpty ? 'Your Name' : fullName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF2C3E50),
                    ),
                  ),
                  if (personalData.birthDateController.text.trim().isNotEmpty ||
                      personalData.birthPlaceController.text.trim().isNotEmpty)
                    pw.Text(
                      [
                        personalData.birthDateController.text.trim(),
                        personalData.birthPlaceController.text.trim(),
                      ].where((s) => s.isNotEmpty).join(' | '),
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ),
            if (personalData.profileImageBytes != null) ...[
              pw.SizedBox(width: 12),
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColor.fromInt(0xFF6964EE),
                ),
                child: pw.Center(
                  child: pw.Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (contactChips.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: contactChips,
          ),
        ],
        if (profileLinks.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Links: ${profileLinks.map((l) => l.labelController.text).join(', ')}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ],
    );
  }

  /// Helper method to build left column for package PDF
  static pw.Widget _buildLeftColumnForPackage(
    ResumeData personalData,
    String birthDate,
    String birthPlace,
    List<LanguageEntry> languages,
    List<SkillSection> skillSections,
  ) {
    final children = <pw.Widget>[];

    // Skills
    if (skillSections.isNotEmpty) {
      children.addAll([
        pw.Text('SKILLS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF34495E))),
        pw.SizedBox(height: 6),
      ]);
      for (final section in skillSections) {
        final sectionTitle = section.titleController.text.trim();
        if (sectionTitle.isNotEmpty) {
          children.add(pw.Text(sectionTitle, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)));
        }
        for (final skill in section.skills) {
          final skillName = skill.nameController.text.trim();
          if (skillName.isNotEmpty) {
            children.add(pw.Text('- $skillName', style: pw.TextStyle(fontSize: 9)));
          }
        }
      }
      children.add(pw.SizedBox(height: 12));
    }

    // Languages
    if (languages.isNotEmpty) {
      children.addAll([
        pw.Text('LANGUAGES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF34495E))),
        pw.SizedBox(height: 6),
      ]);
      for (final lang in languages) {
        final langName = lang.nameController.text.trim();
        final langLevel = lang.level ?? '';
        if (langName.isNotEmpty) {
          children.add(pw.Text('$langName${langLevel.isNotEmpty ? ' ($langLevel)' : ''}', style: pw.TextStyle(fontSize: 9)));
        }
      }
    }

    return pw.Container(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Helper method to build right column for package PDF
  static pw.Widget _buildRightColumnForPackage(
    List<PeriodEntry> workEntries,
    List<PeriodEntry> educationEntries,
  ) {
    final children = <pw.Widget>[];

    // Work Experience
    if (workEntries.isNotEmpty) {
      children.addAll([
        pw.Text('WORK EXPERIENCE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF34495E))),
        pw.SizedBox(height: 6),
      ]);
      for (final entry in workEntries) {
        final title = entry.titleController.text.trim();
        final company = entry.companyController.text.trim();
        final period = ResumePdfService.periodLabel(entry);
        final bullets = entry.bulletPoints;

        if (title.isNotEmpty) {
          children.add(pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)));
        }
        if (company.isNotEmpty || period.isNotEmpty) {
          children.add(pw.Text(
            [company, period].where((s) => s.isNotEmpty).join(' | '),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ));
        }
        if (bullets.isNotEmpty) {
          for (final bullet in bullets) {
            if (bullet.trim().isNotEmpty) {
              children.add(pw.Text('- $bullet', style: pw.TextStyle(fontSize: 9)));
            }
          }
        }
        children.add(pw.SizedBox(height: 8));
      }
    }

    // Education
    if (educationEntries.isNotEmpty) {
      children.addAll([
        pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF34495E))),
        pw.SizedBox(height: 6),
      ]);
      for (final entry in educationEntries) {
        final title = entry.titleController.text.trim();
        final company = entry.companyController.text.trim();
        final period = ResumePdfService.periodLabel(entry);

        if (title.isNotEmpty) {
          children.add(pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)));
        }
        if (company.isNotEmpty || period.isNotEmpty) {
          children.add(pw.Text(
            [company, period].where((s) => s.isNotEmpty).join(' | '),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ));
        }
        children.add(pw.SizedBox(height: 6));
      }
    }

    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Helper method to build footer for package PDF
  static pw.Widget _buildFooterForPackage() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Text(
        'Generated by CV Generator',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  /// Helper method to build cover letter header
  static pw.Widget _buildCoverLetterHeader(String firstName, String email, String phone) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          firstName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2C3E50)),
        ),
        if (email.isNotEmpty || phone.isNotEmpty)
          pw.Text(
            [email, phone].where((s) => s.isNotEmpty).join(' | '),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
      ],
    );
  }

  /// Helper method to create a chip widget
  static pw.Widget _chip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE9EEF3),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  /// Helper method to get current date as string
  static String _getCurrentDate() {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  /// Helper method to sanitize filenames
  static String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
  }
}