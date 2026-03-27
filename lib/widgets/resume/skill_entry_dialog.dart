import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/skill_entry.dart';

/// Dialog for editing a skill entry
class SkillEntryDialog extends StatefulWidget {
  final SkillEntry entry;

  const SkillEntryDialog({
    super.key,
    required this.entry,
  });

  @override
  State<SkillEntryDialog> createState() => _SkillEntryDialogState();
}

class _SkillEntryDialogState extends State<SkillEntryDialog> {
  late final TextEditingController nameCtrl;
  late String? certificatePath;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.entry.nameController.text);
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
      title: const Text('Edit skill'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameCtrl,
              onChanged: (_) {
                if (_showNameError && nameCtrl.text.trim().isNotEmpty) {
                  setState(() => _showNameError = false);
                }
              },
              decoration: InputDecoration(
                labelText: 'Skill name',
                errorText: _showNameError ? 'Please provide a skill name' : null,
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _showNameError ? Colors.red : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _showNameError ? Colors.red : Colors.grey.shade300,
                    width: _showNameError ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _showNameError ? Colors.red : Colors.blue,
                    width: 2,
                  ),
                ),
              ),
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
            if (nameCtrl.text.trim().isEmpty) {
              setState(() => _showNameError = true);
              return;
            }
            Navigator.of(context).pop({
              'name': nameCtrl.text,
              'certificatePath': certificatePath,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
