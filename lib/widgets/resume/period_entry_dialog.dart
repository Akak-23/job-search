import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/period_entry.dart';
import '../../services/resume_data_service.dart';

/// Dialog for editing a period entry (work or education)
class PeriodEntryDialog extends StatefulWidget {
  final PeriodEntry entry;

  const PeriodEntryDialog({
    super.key,
    required this.entry,
  });

  @override
  State<PeriodEntryDialog> createState() => _PeriodEntryDialogState();
}

class _PeriodEntryDialogState extends State<PeriodEntryDialog> {
  late final TextEditingController titleCtrl;
  late final TextEditingController companyCtrl;
  late final TextEditingController startYearCtrl;
  late final TextEditingController endYearCtrl;
  late final TextEditingController bulletsCtrl;
  late String? startMonth;
  late String? endMonth;
  late bool isPresent;
  late String? pdfPath;
  bool _showTitleError = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.entry.titleController.text);
    companyCtrl = TextEditingController(text: widget.entry.companyController.text);
    startYearCtrl = TextEditingController(
      text: widget.entry.startYearController.text,
    );
    endYearCtrl = TextEditingController(
      text: widget.entry.endYearController.text,
    );
    bulletsCtrl = TextEditingController(
      text: widget.entry.bulletsController.text,
    );
    startMonth = widget.entry.startMonth;
    endMonth = widget.entry.endMonth;
    isPresent = widget.entry.isPresent;
    pdfPath = widget.entry.pdfPath;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    companyCtrl.dispose();
    startYearCtrl.dispose();
    endYearCtrl.dispose();
    bulletsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: titleCtrl,
              onChanged: (_) {
                if (_showTitleError && titleCtrl.text.trim().isNotEmpty) {
                  setState(() => _showTitleError = false);
                }
              },
              decoration: InputDecoration(
                labelText: 'Job Title / Degree',
                errorText: _showTitleError ? 'Please provide a title' : null,
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _showTitleError ? Colors.red : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _showTitleError ? Colors.red : Colors.grey.shade300,
                    width: _showTitleError ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _showTitleError ? Colors.red : Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: companyCtrl,
              decoration: const InputDecoration(
                labelText: 'Company / School / University',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Month'),
                    value: startMonth,
                    items: ResumeDataService.months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => startMonth = v),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: startYearCtrl,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Year',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Present'),
                Switch(
                  value: isPresent,
                  onChanged: (v) => setState(() => isPresent = v),
                ),
              ],
            ),
            if (!isPresent) ...[
              const SizedBox(height: 4),
              const Text(
                'End',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Month'),
                      value: endMonth,
                      items: ResumeDataService.months
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => endMonth = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: endYearCtrl,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Year',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Certificate / Document',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (pdfPath != null && pdfPath!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pdfPath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => pdfPath = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(
                pdfPath != null && pdfPath!.isNotEmpty
                    ? 'Change PDF'
                    : 'Upload PDF',
              ),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                  allowMultiple: false,
                );
                if (result != null && result.files.isNotEmpty) {
                  setState(() => pdfPath = result.files.first.path);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: bulletsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bullet points (one per line)',
                hintText: 'e.g. Delivered projects on time\nMentored junior engineers',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (titleCtrl.text.trim().isEmpty) {
              setState(() => _showTitleError = true);
              return;
            }
            Navigator.of(context).pop({
              'title': titleCtrl.text,
              'company': companyCtrl.text,
              'startMonth': startMonth,
              'startYear': startYearCtrl.text,
              'endMonth': endMonth,
              'endYear': endYearCtrl.text,
              'isPresent': isPresent,
              'pdfPath': pdfPath,
              'bullets': _splitBullets(bulletsCtrl.text),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  List<String> _splitBullets(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }
}
