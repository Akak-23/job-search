import 'package:flutter/material.dart';
import '../../utils/application_stage_helper.dart';
import '../../constants/app_strings.dart';

/// Dialog for selecting application stage
class StageSelectionDialog extends StatelessWidget {
  final String currentStage;

  const StageSelectionDialog({
    super.key,
    required this.currentStage,
  });

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case stageSaved:
        return Icons.bookmark;
      case 'Preparing':
        return Icons.edit_document;
      case 'Application Sent':
        return Icons.send;
      case 'Follow-up Phone Call':
        return Icons.phone;
      case stageInterview:
        return Icons.people;
      case 'Negotiations':
        return Icons.handshake;
      case 'Accepted':
        return Icons.check_circle;
      case 'Declined':
        return Icons.close;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Stage'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: ApplicationStageHelper.stages.length,
          itemBuilder: (context, index) {
            final stage = ApplicationStageHelper.stages[index];
            final isSelected = stage == currentStage;
            final stageColor = ApplicationStageHelper.getStageColor(stage);
            final stageIcon = _getStageIcon(stage);
            
            return ListTile(
              title: Text(stage),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  stageIcon,
                  color: stageColor,
                  size: 22,
                ),
              ),
              trailing: isSelected 
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
              selected: isSelected,
              onTap: () => Navigator.of(context).pop(stage),
            );
          },
        ),
      ),
    );
  }
}
