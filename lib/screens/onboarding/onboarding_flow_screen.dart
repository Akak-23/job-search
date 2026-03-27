import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import '../../services/onboarding_service.dart';
import 'welcome_onboarding_screen.dart';
import 'job_type_onboarding_screen.dart';
import 'job_title_onboarding_screen.dart';
import 'location_onboarding_screen.dart';
import 'working_hours_onboarding_screen.dart';
import 'temporary_work_onboarding_screen.dart';
import 'additional_filters_onboarding_screen.dart';

/// Main onboarding flow screen that coordinates all onboarding steps
class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlowScreen({super.key, required this.onComplete});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;
  late JobSearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = JobSearchFilters();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Save the filters first
    await OnboardingService.saveOnboardingFilters(_filters);

    // Mark onboarding as completed
    await OnboardingService.completeOnboarding();

    // Navigate to main app
    if (mounted) {
      widget.onComplete();
    }
  }

  Future<void> _skipOnboarding() async {
    // Mark onboarding as completed without saving filters
    await OnboardingService.completeOnboarding();

    // Navigate to main app
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
        }
      },
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WelcomeOnboardingScreen(
            filters: _filters,
            onNext: _nextStep,
            onSkip: _skipOnboarding,
            currentStep: 1,
            totalSteps: _totalSteps,
          ),
          JobTypeOnboardingScreen(
            filters: _filters,
            onNext: _nextStep,
            onBack: _previousStep,
            onSkip: _skipOnboarding,
            currentStep: 2,
            totalSteps: _totalSteps,
          ),
          JobTitleOnboardingScreen(
            filters: _filters,
            onNext: _nextStep,
            onBack: _previousStep,
            onSkip: _skipOnboarding,
            currentStep: 3,
            totalSteps: _totalSteps,
          ),
          LocationOnboardingScreen(
            filters: _filters,
            onNext: _nextStep,
            onBack: _previousStep,
            onSkip: _skipOnboarding,
            currentStep: 4,
            totalSteps: _totalSteps,
          ),
          WorkingHoursOnboardingScreen(
            filters: _filters,
            onNext: _nextStep,
            onBack: _previousStep,
            onSkip: _skipOnboarding,
            currentStep: 5,
            totalSteps: _totalSteps,
          ),
          TemporaryWorkOnboardingScreen(
            filters: _filters,
            onNext: _nextStep,
            onBack: _previousStep,
            onSkip: _skipOnboarding,
            currentStep: 6,
            totalSteps: _totalSteps,
          ),
          AdditionalFiltersOnboardingScreen(
            filters: _filters,
            onNext: _nextStep,
            onBack: _previousStep,
            onSkip: _skipOnboarding,
            currentStep: 7,
            totalSteps: _totalSteps,
          ),
        ],
      ),
    );
  }
}
