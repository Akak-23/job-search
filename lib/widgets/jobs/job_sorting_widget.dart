import 'package:flutter/material.dart';

/// Widget for job sorting chips
class JobSortingWidget extends StatelessWidget {
  final String sortBy;
  final bool sortAscending;
  final Function(String) onSortChanged;

  const JobSortingWidget({
    super.key,
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sort_rounded,
              size: 20,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sort:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Date', 'date'),
                  const SizedBox(width: 8),
                  _buildSortChip('Title', 'title'),
                  const SizedBox(width: 8),
                  _buildSortChip('Company', 'company'),
                  const SizedBox(width: 8),
                  _buildSortChip('Location', 'location'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String sortKey) {
    final isSelected = sortBy == sortKey;
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              )
            : null,
        color: isSelected ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSortChanged(sortKey),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    letterSpacing: -0.2,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
