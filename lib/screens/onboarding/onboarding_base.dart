import 'package:flutter/material.dart';

/// Base class for onboarding step screens
abstract class OnboardingStepScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final int currentStep;
  final int totalSteps;

  const OnboardingStepScreen({
    super.key,
    required this.onNext,
    this.onBack,
    this.onSkip,
    required this.currentStep,
    required this.totalSteps,
  });
}

/// Base state for onboarding screens with common UI elements
abstract class OnboardingStepState<T extends OnboardingStepScreen>
    extends State<T> {
  /// Build the main content for this step
  Widget buildStepContent();

  /// Title of this onboarding step
  String get stepTitle;

  /// Subtitle/description of this onboarding step
  String get stepSubtitle;

  /// Icon for this onboarding step
  IconData get stepIcon;

  /// Validate if user can proceed to next step
  bool canProceed() => true;

  /// Optional: Build additional bottom content
  Widget? buildAdditionalBottomContent() => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 32),
                    buildStepContent(),
                  ],
                ),
              ),
            ),
            if (buildAdditionalBottomContent() != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: buildAdditionalBottomContent()!,
              ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
              color: const Color(0xFF6366F1),
            ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Step ${widget.currentStep} of ${widget.totalSteps}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.currentStep / widget.totalSteps,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6366F1),
                  ),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          if (widget.onSkip != null)
            const SizedBox(width: 48)
          else if (widget.onBack != null)
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.1),
                const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(stepIcon, size: 48, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(height: 24),
        Text(
          stepTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          stepSubtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (widget.onBack != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: canProceed() ? widget.onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.currentStep == widget.totalSteps
                              ? 'Get Started'
                              : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.onSkip != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: widget.onSkip,
              icon: const Icon(Icons.skip_next, color: Color(0xFF4B5563)),
              label: const Text(
                'Skip onboarding',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: const Color(0xFF4B5563),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
