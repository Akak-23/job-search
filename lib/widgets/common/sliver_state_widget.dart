import 'package:flutter/material.dart';

/// Reusable widget for displaying various states in a Sliver context
/// (loading, error, empty, etc.)
class SliverStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final Widget? customAction;

  const SliverStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = const Color(0xFF6366F1),
    this.onActionPressed,
    this.actionLabel,
    this.customAction,
  });

  /// Factory for error state
  factory SliverStateWidget.error({
    Key? key,
    required String message,
    required VoidCallback onRetry,
  }) {
    return SliverStateWidget(
      key: key,
      icon: Icons.error_outline,
      title: 'Oops! Something Went Wrong',
      message: message,
      iconColor: Colors.red,
      onActionPressed: onRetry,
      actionLabel: 'Try Again',
    );
  }

  /// Factory for empty state
  factory SliverStateWidget.empty({
    Key? key,
    String title = 'No Jobs Found',
    String message =
        'Try adjusting your search filters or\nexpanding your search radius.',
  }) {
    return SliverStateWidget(
      key: key,
      icon: Icons.search_off,
      title: title,
      message: message,
      iconColor: const Color(0xFF6366F1),
    );
  }

  /// Factory for loading state
  factory SliverStateWidget.loading({
    Key? key,
    Color color = const Color(0xFF6366F1),
  }) {
    return SliverStateWidget(
      key: key,
      icon: Icons.hourglass_empty,
      title: '',
      message: '',
      customAction: CircularProgressIndicator(strokeWidth: 3, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customAction != null)
              customAction!
            else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: iconColor),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
              if (onActionPressed != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onActionPressed,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
