import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import 'onboarding_base.dart';

/// Welcome screen - Introduction to the app
class WelcomeOnboardingScreen extends OnboardingStepScreen {
  final JobSearchFilters filters;

  const WelcomeOnboardingScreen({
    super.key,
    required super.onNext,
    super.onBack,
    super.onSkip,
    required super.currentStep,
    required super.totalSteps,
    required this.filters,
  });

  @override
  State<WelcomeOnboardingScreen> createState() =>
      _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState
    extends OnboardingStepState<WelcomeOnboardingScreen> {
  @override
  String get stepTitle => 'Welcome to Job Search';

  @override
  String get stepSubtitle =>
      'Let\'s personalize your job search experience. We\'ll ask you a few questions to help you find the perfect opportunities.';

  @override
  IconData get stepIcon => Icons.waving_hand;

  @override
  Widget buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem(
          icon: Icons.tune,
          title: 'Customized Filters',
          description: 'Set up your preferences once and save time searching',
        ),
        const SizedBox(height: 20),
        _buildFeatureItem(
          icon: Icons.notifications_active,
          title: 'Notifications',
          description: 'Get notified when jobs matching your criteria appear',
        ),
        const SizedBox(height: 20),
        _buildFeatureItem(
          icon: Icons.bookmark,
          title: 'Save Your Searches',
          description: 'Keep track of your favorite search filters',
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This will only take 2-3 minutes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
