import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import 'onboarding_base.dart';

/// Onboarding screen for job title/keyword search
class JobTitleOnboardingScreen extends OnboardingStepScreen {
  final JobSearchFilters filters;

  const JobTitleOnboardingScreen({
    super.key,
    required super.onNext,
    super.onBack,
    super.onSkip,
    required super.currentStep,
    required super.totalSteps,
    required this.filters,
  });

  @override
  State<JobTitleOnboardingScreen> createState() =>
      _JobTitleOnboardingScreenState();
}

class _JobTitleOnboardingScreenState
    extends OnboardingStepState<JobTitleOnboardingScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.filters.was);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get stepTitle => 'What job are you looking for?';

  @override
  String get stepSubtitle =>
      'Enter keywords, job titles, or skills you\'re interested in. You can always change this later.';

  @override
  IconData get stepIcon => Icons.work_outline;

  @override
  Widget buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Job Title or Keywords',
            hintText: 'e.g., Software Developer, Data Analyst',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            setState(() {
              widget.filters.was = value;
            });
          },
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 24),
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
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tips for better results:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Use specific job titles\n'
                      '• Include relevant skills\n'
                      '• Try industry keywords\n'
                      '• Keep it concise',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
