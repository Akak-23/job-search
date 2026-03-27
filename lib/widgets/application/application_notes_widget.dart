import 'package:flutter/material.dart';

/// Widget for managing application notes
class ApplicationNotesWidget extends StatelessWidget {
  final List<Map<String, String>> notes;
  final Function(Map<String, String>) onAddNote;

  const ApplicationNotesWidget({
    super.key,
    required this.notes,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (notes.isEmpty)
          const Text('No notes yet.')
        else
          ...notes.map((note) => _buildNoteCard(note)),
        const SizedBox(height: 12),
        _AddNoteForm(onAddNote: onAddNote),
      ],
    );
  }

  Widget _buildNoteCard(Map<String, String> note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note['note'] ?? ''),
            const SizedBox(height: 4),
            Text(
              'Date/Time: ${note['date'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Correspondent: ${note['correspondent'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddNoteForm extends StatefulWidget {
  final Function(Map<String, String>) onAddNote;

  const _AddNoteForm({required this.onAddNote});

  @override
  State<_AddNoteForm> createState() => _AddNoteFormState();
}

class _AddNoteFormState extends State<_AddNoteForm> {
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController correspondentController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    dateController.dispose();
    correspondentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Add Note',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: dateController,
          decoration: const InputDecoration(
            labelText: 'Date/Time',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: correspondentController,
          decoration: const InputDecoration(
            labelText: 'Correspondent',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addNote,
          child: const Text('Add Note'),
        ),
      ],
    );
  }

  void _addNote() {
    if (noteController.text.isNotEmpty) {
      widget.onAddNote({
        'note': noteController.text,
        'date': dateController.text,
        'correspondent': correspondentController.text,
      });
      
      noteController.clear();
      dateController.clear();
      correspondentController.clear();
    }
  }
}
