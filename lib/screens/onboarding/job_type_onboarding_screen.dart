import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import '../../widgets/filter_option_card.dart';
import 'onboarding_base.dart';

/// Onboarding screen for job type selection
class JobTypeOnboardingScreen extends OnboardingStepScreen {
  final JobSearchFilters filters;

  const JobTypeOnboardingScreen({
    super.key,
    required super.onNext,
    super.onBack,
    super.onSkip,
    required super.currentStep,
    required super.totalSteps,
    required this.filters,
  });

  @override
  State<JobTypeOnboardingScreen> createState() =>
      _JobTypeOnboardingScreenState();
}

class _JobTypeOnboardingScreenState
    extends OnboardingStepState<JobTypeOnboardingScreen> {
  @override
  String get stepTitle => 'What type of job are you looking for?';

  @override
  String get stepSubtitle =>
      'Choose the types of opportunities you\'re interested in.';

  @override
  IconData get stepIcon => Icons.business_center_outlined;

  @override
  bool canProceed() => widget.filters.angebotsartList.isNotEmpty;

  @override
  Widget buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilterOptionCard(
                label: 'Employment',
                icon: Icons.work_outline,
                isSelected: widget.filters.angebotsartList.contains('1'),
                onTap: () {
                  setState(() {
                    if (widget.filters.angebotsartList.contains('1')) {
                      widget.filters.angebotsartList.remove('1');
                    } else {
                      widget.filters.angebotsartList.add('1');
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterOptionCard(
                label: 'Self-Employment',
                icon: Icons.storefront_outlined,
                isSelected: widget.filters.angebotsartList.contains('2'),
                onTap: () {
                  setState(() {
                    if (widget.filters.angebotsartList.contains('2')) {
                      widget.filters.angebotsartList.remove('2');
                    } else {
                      widget.filters.angebotsartList.add('2');
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilterOptionCard(
                label: 'Training',
                icon: Icons.school_outlined,
                isSelected: widget.filters.angebotsartList.contains('4'),
                onTap: () {
                  setState(() {
                    if (widget.filters.angebotsartList.contains('4')) {
                      widget.filters.angebotsartList.remove('4');
                    } else {
                      widget.filters.angebotsartList.add('4');
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterOptionCard(
                label: 'Internship',
                icon: Icons.trending_up_outlined,
                isSelected: widget.filters.angebotsartList.contains('34'),
                onTap: () {
                  setState(() {
                    if (widget.filters.angebotsartList.contains('34')) {
                      widget.filters.angebotsartList.remove('34');
                    } else {
                      widget.filters.angebotsartList.add('34');
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (widget.filters.angebotsartList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade200.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please select at least one option to continue',
                    style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
