import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import '../../widgets/filter_option_card.dart';
import 'onboarding_base.dart';

/// Onboarding screen for working hours preference
class WorkingHoursOnboardingScreen extends OnboardingStepScreen {
  final JobSearchFilters filters;

  const WorkingHoursOnboardingScreen({
    super.key,
    required super.onNext,
    super.onBack,
    super.onSkip,
    required super.currentStep,
    required super.totalSteps,
    required this.filters,
  });

  @override
  State<WorkingHoursOnboardingScreen> createState() =>
      _WorkingHoursOnboardingScreenState();
}

class _WorkingHoursOnboardingScreenState
    extends OnboardingStepState<WorkingHoursOnboardingScreen> {
  @override
  String get stepTitle => 'What are your preferred working hours?';

  @override
  String get stepSubtitle =>
      'Select one or more options. We\'ll show jobs that match your preferences.';

  @override
  IconData get stepIcon => Icons.schedule;

  @override
  bool canProceed() => widget.filters.arbeitszeit.isNotEmpty;

  @override
  Widget buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilterOptionCard(
                label: 'Full-time',
                icon: Icons.work_outline,
                isSelected: widget.filters.arbeitszeit.contains('vz'),
                onTap: () {
                  setState(() {
                    if (widget.filters.arbeitszeit.contains('vz')) {
                      widget.filters.arbeitszeit.remove('vz');
                    } else {
                      widget.filters.arbeitszeit.add('vz');
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterOptionCard(
                label: 'Part-time',
                icon: Icons.schedule,
                isSelected: widget.filters.arbeitszeit.contains('tz'),
                onTap: () {
                  setState(() {
                    if (widget.filters.arbeitszeit.contains('tz')) {
                      widget.filters.arbeitszeit.remove('tz');
                    } else {
                      widget.filters.arbeitszeit.add('tz');
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
                label: 'Remote',
                icon: Icons.computer,
                isSelected: widget.filters.arbeitszeit.contains('ho'),
                onTap: () {
                  setState(() {
                    if (widget.filters.arbeitszeit.contains('ho')) {
                      widget.filters.arbeitszeit.remove('ho');
                    } else {
                      widget.filters.arbeitszeit.add('ho');
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterOptionCard(
                label: 'Shift/Night',
                icon: Icons.nights_stay_outlined,
                isSelected: widget.filters.arbeitszeit.contains('snw'),
                onTap: () {
                  setState(() {
                    if (widget.filters.arbeitszeit.contains('snw')) {
                      widget.filters.arbeitszeit.remove('snw');
                    } else {
                      widget.filters.arbeitszeit.add('snw');
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
                label: 'Mini/Midi Job',
                icon: Icons.access_time,
                isSelected: widget.filters.arbeitszeit.contains('mj'),
                onTap: () {
                  setState(() {
                    if (widget.filters.arbeitszeit.contains('mj')) {
                      widget.filters.arbeitszeit.remove('mj');
                    } else {
                      widget.filters.arbeitszeit.add('mj');
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 24),
        if (widget.filters.arbeitszeit.isEmpty)
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
