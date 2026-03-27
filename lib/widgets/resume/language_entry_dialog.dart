import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/language_entry.dart';
import '../../services/resume_data_service.dart';

/// Dialog for editing a language entry
class LanguageEntryDialog extends StatefulWidget {
  final LanguageEntry entry;

  const LanguageEntryDialog({
    super.key,
    required this.entry,
  });

  @override
  State<LanguageEntryDialog> createState() => _LanguageEntryDialogState();
}

class _LanguageEntryDialogState extends State<LanguageEntryDialog> {
  late final TextEditingController nameCtrl;
  late String? level;
  late String? certificatePath;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.entry.nameController.text);
    level = widget.entry.level;
    certificatePath = widget.entry.certificatePath;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit language'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Language'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Level',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select level'),
              value: level,
              items: ResumeDataService.languageLevels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => level = v),
            ),
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
            if (certificatePath != null && certificatePath!.isNotEmpty) ...[
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
                        certificatePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => certificatePath = null),
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
                certificatePath != null && certificatePath!.isNotEmpty
                    ? 'Change Certificate'
                    : 'Upload Certificate',
              ),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                  allowMultiple: false,
                );
                if (result != null && result.files.isNotEmpty) {
                  setState(() => certificatePath = result.files.first.path);
                }
              },
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
            Navigator.of(context).pop({
              'name': nameCtrl.text,
              'level': level,
              'certificatePath': certificatePath,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
