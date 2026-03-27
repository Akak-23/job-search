import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import 'onboarding_base.dart';

/// Onboarding screen for location and radius selection
class LocationOnboardingScreen extends OnboardingStepScreen {
  final JobSearchFilters filters;

  const LocationOnboardingScreen({
    super.key,
    required super.onNext,
    super.onBack,
    super.onSkip,
    required super.currentStep,
    required super.totalSteps,
    required this.filters,
  });

  @override
  State<LocationOnboardingScreen> createState() =>
      _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState
    extends OnboardingStepState<LocationOnboardingScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.filters.wo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get stepTitle => 'Where do you want to work?';

  @override
  String get stepSubtitle =>
      'Set your preferred location and search radius. This helps us find jobs near you.';

  @override
  IconData get stepIcon => Icons.location_on_outlined;

  @override
  Widget buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'City or Postal Code',
            hintText: 'e.g., Berlin, 10115',
            prefixIcon: const Icon(Icons.place_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            setState(() {
              widget.filters.wo = value;
            });
          },
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 32),
        Text(
          'Search Radius',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.filters.umkreis.toInt()} km',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRadiusLabel(widget.filters.umkreis.toInt()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF6366F1),
                  inactiveTrackColor: const Color(0xFFE0E7FF),
                  thumbColor: const Color(0xFF6366F1),
                  overlayColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: widget.filters.umkreis,
                  min: 5,
                  max: 200,
                  divisions: 39,
                  label: '${widget.filters.umkreis.toInt()} km',
                  onChanged: (value) {
                    setState(() {
                      widget.filters.umkreis = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '5 km',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '200 km',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
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
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Remote jobs will be included regardless of radius',
                  style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRadiusLabel(int km) {
    if (km < 20) return 'Very Local';
    if (km < 50) return 'Local';
    if (km < 100) return 'Regional';
    return 'Wide Area';
  }
}
