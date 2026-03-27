import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../models/period_entry.dart';
import '../models/skill_section.dart';
import '../models/language_entry.dart';
import '../models/profile_link.dart';
import '../models/resume_data.dart';
import '../services/resume_data_service.dart';
import 'pdf_file_saver.dart';

/// Service for exporting resume data to PDF
class ResumePdfService {
  // Professional color scheme
  static const accentColor = PdfColor.fromInt(0xFF2F3E4E);
  static const headingColor = PdfColor.fromInt(0xFF2F3E4E);
  static const textColor = PdfColor.fromInt(0xFF2C3E50);
  static const mutedText = PdfColors.grey700;
  static const lightGrey = PdfColor.fromInt(0xFFF1F3F6);
  static const dividerColor = PdfColor.fromInt(0xFFD5D9DE);
  static const sidebarColor = PdfColor.fromInt(0xFFF4F6F8);
  static const chipColor = PdfColor.fromInt(0xFFE6EAEE);
  
  // Spacing constants
  static const double largeSpacing = 18;
  static const double mediumSpacing = 12;
  static const double smallSpacing = 8;
  static const double tinySpacing = 4;
  
  // Sizing constants
  static const double profileImageSize = 128;
  static const double sidebarWidth = 190;
  static const double headerTitleSize = 24;
  static const double headerSubtitleSize = 11;
  static const double sectionTitleSize = 10.5;

  static String periodLabel(PeriodEntry e) {
    final startParts = <String>[];
    final endParts = <String>[];

    final startMonth = e.startMonth?.trim() ?? '';
    if (startMonth.isNotEmpty) {
      startParts.add(startMonth);
    }
    
    final startYear = e.startYearController.text.trim();
    if (startYear.isNotEmpty) startParts.add(startYear);

    final endMonth = e.endMonth?.trim() ?? '';
    if (endMonth.isNotEmpty) {
      endParts.add(endMonth);
    }
    
    final endYear = e.endYearController.text.trim();
    if (endYear.isNotEmpty) endParts.add(endYear);

    final startText = startParts.join(' ');
    final endText = e.isPresent ? 'Present' : endParts.join(' ');

    final buffer = <String>[];
    if (startText.isNotEmpty) buffer.add(startText);
    if (endText.isNotEmpty) buffer.add(endText);

    if (buffer.isEmpty) return '';
    return buffer.join(' - ');
  }

  static List<PeriodEntry> sortedFilledPeriods(List<PeriodEntry> list) {
    final copy = list
        .where((e) => e.titleController.text.trim().isNotEmpty)
        .toList();
    copy.sort(_compareEntries);
    return copy;
  }

  static DateTime _entryEndDate(PeriodEntry e) {
    if (e.isPresent) return DateTime(9999);
    final y = int.tryParse(e.endYearController.text.trim());
    final m = ResumeDataService.months.indexOf(e.endMonth ?? '') + 1;
    if (y != null) return DateTime(y, m.clamp(1, 12));
    return DateTime(0);
  }

  static DateTime _entryStartDate(PeriodEntry e) {
    final y = int.tryParse(e.startYearController.text.trim());
    final m = ResumeDataService.months.indexOf(e.startMonth ?? '') + 1;
    if (y != null) return DateTime(y, m.clamp(1, 12));
    return DateTime(0);
  }

  static int _compareEntries(PeriodEntry a, PeriodEntry b) {
    final aEnd = _entryEndDate(a);
    final bEnd = _entryEndDate(b);
    final endCompare = bEnd.compareTo(aEnd); // descending
    if (endCompare != 0) return endCompare;
    final aStart = _entryStartDate(a);
    final bStart = _entryStartDate(b);
    return bStart.compareTo(aStart); // descending
  }

  static Future<Uint8List> generatePdfBytes({
    required ResumeData personalData,
    required List<PeriodEntry> workEntries,
    required List<PeriodEntry> educationEntries,
    required List<SkillSection> skillSections,
    required List<LanguageEntry> languageEntries,
    required List<ProfileLink> profileLinks,
  }) async {
    final workEntriesSorted = sortedFilledPeriods(workEntries);
    final educationEntriesSorted = sortedFilledPeriods(educationEntries);
    final languages = languageEntries
        .where((e) => _isNotEmpty(e.nameController.text))
        .toList();

    final fullName = personalData.fullName;
    final birthDate = personalData.birthDateController.text.trim();
    final birthPlace = personalData.birthPlaceController.text.trim();
    final streetLine = personalData.streetLine;
    final cityLine = personalData.cityLine;

    final doc = pw.Document();

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
              _buildHeader(personalData, fullName, streetLine, cityLine, profileLinks),
              pw.SizedBox(height: largeSpacing),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildLeftColumn(
                    personalData,
                    birthDate,
                    birthPlace,
                    languages,
                    skillSections,
                    profileLinks,
                  ),
                  pw.SizedBox(width: largeSpacing),
                  _buildRightColumn(
                    workEntriesSorted,
                    educationEntriesSorted,
                  ),
                ],
              ),
              pw.SizedBox(height: smallSpacing),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<String> exportToPdf({
    required ResumeData personalData,
    required List<PeriodEntry> workEntries,
    required List<PeriodEntry> educationEntries,
    required List<SkillSection> skillSections,
    required List<LanguageEntry> languageEntries,
    required List<ProfileLink> profileLinks,
  }) async {
    final bytes = await generatePdfBytes(
      personalData: personalData,
      workEntries: workEntries,
      educationEntries: educationEntries,
      skillSections: skillSections,
      languageEntries: languageEntries,
      profileLinks: profileLinks,
    );
    final filename = _buildFileName(personalData.fullName);
    return savePdf(bytes: bytes, filename: filename);
  }

  static String _buildFileName(String fullName) {
    final normalizedName = fullName
        .trim()
        .replaceAll(RegExp(r"\s+"), '_')
        .replaceAll(RegExp(r"[^A-Za-z0-9_\-]"), '');
    final suffix = normalizedName.isEmpty ? '' : '_$normalizedName';
    return 'Resume$suffix.pdf';
  }

  static String exportFileName(String fullName) => _buildFileName(fullName);

  static bool _isNotEmpty(String text) => text.trim().isNotEmpty;

  static String _getTrimmedText(TextEditingController controller) =>
      controller.text.trim();

  static pw.Widget _buildHeader(
    ResumeData personalData,
    String fullName,
    String streetLine,
    String cityLine,
    List<ProfileLink> profileLinks,
  ) {
    final contactChips = _buildContactChips(personalData, streetLine, cityLine);
    
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: accentColor,
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            fullName.isEmpty ? 'Curriculum Vitae' : fullName,
            style: pw.TextStyle(
              fontSize: headerTitleSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: tinySpacing),
          pw.Text(
            'Resume',
            style: pw.TextStyle(
              fontSize: headerSubtitleSize,
              color: PdfColor.fromInt(0xFFDDE3EA),
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          if (contactChips.isNotEmpty) ...[
            pw.SizedBox(height: mediumSpacing),
            pw.Wrap(
              spacing: smallSpacing,
              runSpacing: smallSpacing,
              children: contactChips,
            ),
          ],
        ],
      ),
    );
  }

  static List<pw.Widget> _buildContactChips(
    ResumeData personalData,
    String streetLine,
    String cityLine,
  ) {
    final chips = <pw.Widget>[];
    
    final email = _getTrimmedText(personalData.emailController);
    if (email.isNotEmpty) {
      chips.add(_chip('Email', email));
    }
    
    final phone = _getTrimmedText(personalData.phoneController);
    if (phone.isNotEmpty) {
      chips.add(_chip('Phone', phone));
    }
    
    final address = [streetLine, cityLine].where((s) => s.isNotEmpty).join(', ');
    if (address.isNotEmpty) {
      chips.add(_chip('Address', address));
    }
    
    return chips;
  }

  static pw.Widget _buildLeftColumn(
    ResumeData personalData,
    String birthDate,
    String birthPlace,
    List<LanguageEntry> languages,
    List<SkillSection> skillSections,
    List<ProfileLink> profileLinks,
  ) {
    final profileImage = _profileImageProvider(personalData.profileImageBytes);
    return pw.Container(
      width: sidebarWidth,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: sidebarColor,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: dividerColor, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (profileImage != null)
            ..._buildProfileImage(profileImage),
          _sectionTitle('Personal Details'),
          if (birthDate.isNotEmpty) _dataField('Date of Birth', birthDate),
          if (birthPlace.isNotEmpty) _dataField('Place of Birth', birthPlace),
          pw.SizedBox(height: mediumSpacing),
          if (languages.isNotEmpty)
            ..._buildLanguagesSection(languages),
          ..._buildLinksSection(profileLinks),
          if (skillSections.isNotEmpty)
            ..._buildSkillSections(skillSections),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildProfileImage(pw.MemoryImage image) {
    return [
      pw.Center(
        child: pw.Container(
          width: profileImageSize,
          height: profileImageSize,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: dividerColor, width: 1),
            image: pw.DecorationImage(
              image: image,
              fit: pw.BoxFit.cover,
            ),
          ),
        ),
      ),
      pw.SizedBox(height: 16),
    ];
  }

  static List<pw.Widget> _buildLanguagesSection(
    List<LanguageEntry> languages,
  ) {
    return [
      _sectionTitle('Languages'),
      ...languages.map(
        (l) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: tinySpacing),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _getTrimmedText(l.nameController),
                  style: pw.TextStyle(fontSize: 9, color: textColor),
                ),
              ),
              if (l.level != null)
                pw.Text(
                  l.level!,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: mutedText,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: mediumSpacing),
    ];
  }

  static List<pw.Widget> _buildLinksSection(List<ProfileLink> profileLinks) {
    final filledLinks = profileLinks
        .where((link) =>
            _isNotEmpty(_getTrimmedText(link.labelController)) &&
            _isNotEmpty(_getTrimmedText(link.urlController)))
        .toList();

    if (filledLinks.isEmpty) return <pw.Widget>[];

    return [
      _sectionTitle('Links'),
      ...filledLinks.map(
        (link) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: smallSpacing),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _getTrimmedText(link.labelController),
                style: pw.TextStyle(
                  fontSize: 9,
                  color: textColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.UrlLink(
                destination: _getTrimmedText(link.urlController),
                child: pw.Text(
                  _getTrimmedText(link.urlController),
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: accentColor,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: mediumSpacing),
    ];
  }

  static List<pw.Widget> _buildSkillSections(List<SkillSection> skillSections) {
    return skillSections
        .where((s) => s.skills.any((skill) =>
            _isNotEmpty(_getTrimmedText(skill.nameController))))
        .map((section) {
          final filledSkills = section.skills
              .where((s) => _isNotEmpty(_getTrimmedText(s.nameController)))
              .toList();
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle(_getTrimmedText(section.titleController)),
              pw.Wrap(
                spacing: smallSpacing,
                runSpacing: smallSpacing,
                children: filledSkills
                    .map(
                      (s) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: tinySpacing,
                        ),
                        decoration: pw.BoxDecoration(
                          color: chipColor,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          _getTrimmedText(s.nameController),
                          style: pw.TextStyle(fontSize: 8.5, color: textColor),
                        ),
                      ),
                    )
                    .toList(),
              ),
              pw.SizedBox(height: smallSpacing),
            ],
          );
        })
        .toList();
  }

  static pw.MemoryImage? _profileImageProvider(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;

    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return pw.MemoryImage(bytes);
      }

      // Resample to high quality for PDF export
      // Keep original dimensions but ensure high quality encoding
      final resized = img.copyResize(
        decoded,
        width: decoded.width,
        height: decoded.height,
        interpolation: img.Interpolation.cubic,
      );

      // Encode as high-quality PNG (compression level 9 for better quality)
      final pngBytes = Uint8List.fromList(img.encodePng(resized, level: 9));
      return pw.MemoryImage(pngBytes);
    } catch (_) {
      return pw.MemoryImage(bytes);
    }
  }

  static pw.Widget _buildRightColumn(
    List<PeriodEntry> workEntries,
    List<PeriodEntry> educationEntries,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Work Experience'),
          _sectionContent(
            entries: workEntries,
            emptyText: 'No work experience provided',
          ),
          pw.SizedBox(height: largeSpacing),
          _sectionTitle('Education'),
          _sectionContent(
            entries: educationEntries,
            emptyText: 'No education provided',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.SizedBox.shrink();
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: pw.FontWeight.bold,
            color: headingColor,
            letterSpacing: 1.4,
          ),
        ),
        pw.SizedBox(height: tinySpacing),
        pw.Container(height: 2, width: 36, color: headingColor),
        pw.SizedBox(height: smallSpacing),
      ],
    );
  }

  static pw.Widget _sectionContent({
    required List<PeriodEntry> entries,
    required String emptyText,
  }) {
    if (entries.isEmpty) {
      return pw.Text(
        emptyText,
        style: pw.TextStyle(
          fontSize: 9,
          color: mutedText,
          fontStyle: pw.FontStyle.italic,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: entries.map(_experienceEntry).toList(),
    );
  }

  static pw.Widget _chip(String icon, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1F2E3A),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            icon,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Flexible(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
              ),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dataField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: mutedText,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9, color: textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _experienceEntry(PeriodEntry entry) {
    final periodText = periodLabel(entry);
    final bullets = entry.bulletPoints
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    final title = _getTrimmedText(entry.titleController);
    final company = _getTrimmedText(entry.companyController);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: mediumSpacing),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildBulletPoint(),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildEntryHeader(title, company, periodText),
                    pw.SizedBox(height: tinySpacing),
                    pw.Container(height: 0.8, color: dividerColor),
                    if (bullets.isNotEmpty)
                      ..._buildBulletList(bullets),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletPoint() {
    return pw.Container(
      width: 8,
      height: 8,
      margin: const pw.EdgeInsets.only(top: 3, right: 10),
      decoration: pw.BoxDecoration(
        color: accentColor,
        shape: pw.BoxShape.circle,
      ),
    );
  }

  static pw.Widget _buildEntryHeader(
    String title,
    String company,
    String periodText,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: headingColor,
                ),
              ),
              if (company.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    company,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (periodText.isNotEmpty)
          pw.Text(
            periodText,
            style: pw.TextStyle(
              fontSize: 9,
              color: mutedText,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
      ],
    );
  }

  static List<pw.Widget> _buildBulletList(List<String> bullets) {
    return [
      pw.SizedBox(height: smallSpacing),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: bullets
            .map(
              (b) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: tinySpacing, left: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSmallBulletPoint(),
                    pw.Expanded(
                      child: pw.Text(
                        b,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ];
  }

  static pw.Widget _buildSmallBulletPoint() {
    return pw.Container(
      width: 4,
      height: 4,
      margin: const pw.EdgeInsets.only(top: 4, right: 6),
      decoration: pw.BoxDecoration(
        color: accentColor,
        shape: pw.BoxShape.circle,
      ),
    );
  }
}
