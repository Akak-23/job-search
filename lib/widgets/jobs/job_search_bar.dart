import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';

/// Compact search bar with quick actions
class JobSearchBar extends StatelessWidget {
  final TextEditingController wasController;
  final JobSearchFilters filters;
  final VoidCallback onToggleAdvanced;
  final VoidCallback? onSearch;
  final bool showAdvanced;

  const JobSearchBar({
    super.key,
    required this.wasController,
    required this.filters,
    required this.onToggleAdvanced,
    this.onSearch,
    required this.showAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: wasController,
              decoration: InputDecoration(
                hintText: 'Search for jobs...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                filled: true,
                isDense: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                suffixIcon: wasController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          wasController.clear();
                          filters.was = '';
                        },
                        color: Colors.grey.shade600,
                      )
                    : null,
              ),
              onChanged: (v) => filters.was = v,
              onSubmitted: (value) {
                filters.was = value;
                if (onSearch != null) {
                  onSearch!();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                showAdvanced ? Icons.expand_less : Icons.tune,
                color: const Color(0xFF6366F1),
              ),
              tooltip: showAdvanced ? 'Fewer Filters' : 'More Filters',
              onPressed: onToggleAdvanced,
            ),
          ),
        ],
      ),
    );
  }
}
