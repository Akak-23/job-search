import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import 'onboarding_base.dart';

/// Onboarding screen for additional filters (employer, field, posted date)
class AdditionalFiltersOnboardingScreen extends OnboardingStepScreen {
  final JobSearchFilters filters;

  const AdditionalFiltersOnboardingScreen({
    super.key,
    required super.onNext,
    super.onBack,
    super.onSkip,
    required super.currentStep,
    required super.totalSteps,
    required this.filters,
  });

  @override
  State<AdditionalFiltersOnboardingScreen> createState() =>
      _AdditionalFiltersOnboardingScreenState();
}

class _AdditionalFiltersOnboardingScreenState
    extends OnboardingStepState<AdditionalFiltersOnboardingScreen> {
  late TextEditingController _arbeitgeberController;
  late TextEditingController _berufsfeldController;

  @override
  void initState() {
    super.initState();
    _arbeitgeberController = TextEditingController(
      text: widget.filters.arbeitgeber,
    );
    _berufsfeldController = TextEditingController(
      text: widget.filters.berufsfeld,
    );
  }

  @override
  void dispose() {
    _arbeitgeberController.dispose();
    _berufsfeldController.dispose();
    super.dispose();
  }

  @override
  String get stepTitle => 'Any specific preferences?';

  @override
  String get stepSubtitle =>
      'These are optional but can help refine your search results.';

  @override
  IconData get stepIcon => Icons.tune;

  @override
  Widget buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _arbeitgeberController,
          decoration: InputDecoration(
            labelText: 'Preferred Employer (Optional)',
            hintText: 'e.g., Siemens, BMW',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            widget.filters.arbeitgeber = value;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _berufsfeldController,
          decoration: InputDecoration(
            labelText: 'Professional Field (Optional)',
            hintText: 'e.g., IT, Healthcare',
            prefixIcon: const Icon(Icons.category_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            widget.filters.berufsfeld = value;
          },
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
