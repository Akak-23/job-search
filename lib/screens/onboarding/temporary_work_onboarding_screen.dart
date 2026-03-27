import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import '../../widgets/filter_option_card.dart';
import 'onboarding_base.dart';

/// Onboarding screen for temporary work companies preference
class TemporaryWorkOnboardingScreen extends OnboardingStepScreen {
  final JobSearchFilters filters;

  const TemporaryWorkOnboardingScreen({
    super.key,
    required super.onNext,
    super.onBack,
    super.onSkip,
    required super.currentStep,
    required super.totalSteps,
    required this.filters,
  });

  @override
  State<TemporaryWorkOnboardingScreen> createState() =>
      _TemporaryWorkOnboardingScreenState();
}

class _TemporaryWorkOnboardingScreenState
    extends OnboardingStepState<TemporaryWorkOnboardingScreen> {
  @override
  String get stepTitle => 'Temporary work companies?';

  @override
  String get stepSubtitle =>
      'Do you want to work for temporary work agencies?';

  @override
  IconData get stepIcon => Icons.work_history_outlined;

  @override
  Widget buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilterOptionCard(
                label: 'Include',
                icon: Icons.check_circle_outline,
                isSelected: widget.filters.zeitarbeit == true,
                onTap: () {
                  setState(() {
                    widget.filters.zeitarbeit = true;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterOptionCard(
                label: 'Exclude',
                icon: Icons.cancel_outlined,
                isSelected: widget.filters.zeitarbeit == false,
                onTap: () {
                  setState(() {
                    widget.filters.zeitarbeit = false;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.shade200.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'What is Zeitarbeit?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Temporary work companies (Zeitarbeitsfirmen) employ workers and lease them to other companies. These positions may be temporary or can lead to permanent employment.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[900],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.filters.zeitarbeit
                      ? 'Including temporary work companies will show you only jobs from agencies.'
                      : 'Excluding temporary work companies will only show direct employer positions.',
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
