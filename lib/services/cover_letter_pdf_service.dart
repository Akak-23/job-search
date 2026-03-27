import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_file_saver.dart';

/// Service for exporting cover letters to PDF
class CoverLetterPdfService {
  // Professional color scheme
  static const accentColor = PdfColor.fromInt(0xFF2C3E50);
  static const textColor = PdfColor.fromInt(0xFF2C3E50);
  static const mutedText = PdfColors.grey700;

  static String buildFileName(String firstName, String lastName) {
    final safeFirst = firstName.trim().replaceAll(RegExp(r"\s+"), '_');
    final safeLast = lastName.trim().replaceAll(RegExp(r"\s+"), '_');
    final namePart = [safeFirst, safeLast]
        .where((p) => p.isNotEmpty)
        .join('_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return namePart.isEmpty
        ? 'cover_letter_$timestamp.pdf'
        : 'cover_letter_${namePart}_$timestamp.pdf';
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

  static Future<String> exportToPdf({
    required String coverLetterText,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String jobTitle = '',
    String company = '',
  }) async {
    final pdf = pw.Document();

    // Create a professional cover letter PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(firstName, lastName, email, phone),
              pw.SizedBox(height: 24),
              pw.Text(
                _getCurrentDate(),
                style: pw.TextStyle(color: mutedText, fontSize: 10),
              ),
              pw.SizedBox(height: 14),
              if (company.isNotEmpty) ...[
                pw.Text('Hiring Manager', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(company, style: pw.TextStyle(color: textColor, fontSize: 11)),
                pw.SizedBox(height: 12),
              ],
              pw.Text('Dear Hiring Manager,', style: pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 12),
              ..._buildParagraphs(_sanitizeCoverLetterText(coverLetterText)),
              pw.SizedBox(height: 20),
              pw.Text('Sincerely,', style: pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 12),
              pw.Text('$firstName $lastName', style: pw.TextStyle(fontSize: 11)),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    
    // Generate filename
    final filename = buildFileName(firstName, lastName);

    // Save to device
    final savedPath = await savePdf(bytes: bytes, filename: filename);
    
    return savedPath;
  }

  static pw.Widget _buildHeader(String firstName, String lastName, String email, String phone) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$firstName $lastName',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
          ),
        ),
        pw.SizedBox(height: 4),
        if (email.isNotEmpty || phone.isNotEmpty)
          pw.Text(
            [email, phone].where((s) => s.isNotEmpty).join(' • '),
            style: pw.TextStyle(fontSize: 10, color: mutedText),
          ),
      ],
    );
  }

  static List<pw.Widget> _buildParagraphs(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      return [pw.Text('', style: pw.TextStyle(fontSize: 11, height: 1.5))];
    }

    final paragraphs = cleaned.split(RegExp(r'\n\s*\n')).map((p) => p.trim());
    final widgets = <pw.Widget>[];
    for (final paragraph in paragraphs) {
      if (paragraph.isEmpty) continue;
      widgets.add(
        pw.Text(
          paragraph,
          style: pw.TextStyle(fontSize: 11, height: 1.5, color: textColor),
        ),
      );
      widgets.add(pw.SizedBox(height: 10));
    }
    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }
    return widgets;
  }

  static String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}