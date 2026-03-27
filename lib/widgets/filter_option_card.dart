import 'package:flutter/material.dart';

/// A reusable filter option card widget matching Figma design
/// Shows as a selectable card with icon, label, and checkbox
class FilterOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  const FilterOptionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = const Color(0xFF6964EE), // Primary purple
    this.unselectedColor = const Color(0xFF9296AB), // Gray text
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? const Color(0xFFEEF2FF) // Light purple background
        : const Color(0xFFF9F9FB); // Light gray background

    final borderColor = isSelected
        ? const Color.fromARGB(102, 105, 100, 238) // rgba(105, 100, 238, 0.4)
        : const Color.fromARGB(13, 105, 100, 238); // rgba(105, 100, 238, 0.05)

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with background circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3FF),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD3DDFF).withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
            const SizedBox(height: 12),
            // Label
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: -0.02,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
