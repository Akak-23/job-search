import 'package:flutter/material.dart';
import '../../models/job_search_filters.dart';
import '../filter_option_card.dart';

/// Advanced filters section (expandable)
class AdvancedFiltersSection extends StatelessWidget {
  final JobSearchFilters filters;
  final TextEditingController arbeitgeberController;
  final TextEditingController berufsfeldController;
  final TextEditingController veroeffentlichtseitController;
  final VoidCallback onSaveFilter;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback onShowLocationDialog;
  final Function(String) onArbeitszeitChanged;
  final Function(String) onAngebotsartChanged;
  final Function(bool) onZeitarbeitChanged;

  const AdvancedFiltersSection({
    super.key,
    required this.filters,
    required this.arbeitgeberController,
    required this.berufsfeldController,
    required this.veroeffentlichtseitController,
    required this.onSaveFilter,
    required this.onSearch,
    required this.onClear,
    required this.onShowLocationDialog,
    required this.onArbeitszeitChanged,
    required this.onAngebotsartChanged,
    required this.onZeitarbeitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                      Icons.tune,
                      size: 20,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Advanced Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
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
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_add, color: Colors.white),
                      tooltip: 'Save current search',
                      onPressed: onSaveFilter,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: arbeitgeberController,
                      decoration: InputDecoration(
                        labelText: 'Employer',
                        hintText: 'e.g. Siemens',
                        prefixIcon: Icon(
                          Icons.business,
                          color: Colors.grey[600],
                        ),
                      ),
                      onChanged: (v) => filters.arbeitgeber = v,
                      onSubmitted: (value) {
                        filters.arbeitgeber = value;
                        onSearch();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: berufsfeldController,
                      decoration: InputDecoration(
                        labelText: 'Field',
                        hintText: 'e.g. IT',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Colors.grey[600],
                        ),
                      ),
                      onChanged: (v) => filters.berufsfeld = v,
                      onSubmitted: (value) {
                        filters.berufsfeld = value;
                        onSearch();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Arbeitszeit (Working Hours) Filter
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text(
                    'Working Hours',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  initiallyExpanded: false,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Full-time',
                                  icon: Icons.work_outline,
                                  isSelected: filters.arbeitszeit.contains(
                                    'vz',
                                  ),
                                  onTap: () => onArbeitszeitChanged('vz'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Part-time',
                                  icon: Icons.schedule,
                                  isSelected: filters.arbeitszeit.contains(
                                    'tz',
                                  ),
                                  onTap: () => onArbeitszeitChanged('tz'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Remote',
                                  icon: Icons.computer,
                                  isSelected: filters.arbeitszeit.contains(
                                    'ho',
                                  ),
                                  onTap: () => onArbeitszeitChanged('ho'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Shift/Night',
                                  icon: Icons.nights_stay_outlined,
                                  isSelected: filters.arbeitszeit.contains(
                                    'snw',
                                  ),
                                  onTap: () => onArbeitszeitChanged('snw'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Mini/Midi Job',
                                  icon: Icons.access_time,
                                  isSelected: filters.arbeitszeit.contains(
                                    'mj',
                                  ),
                                  onTap: () => onArbeitszeitChanged('mj'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Angebotsart (Job Type) Filter
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text(
                    'Job Type',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  initiallyExpanded: false,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Employment',
                                  icon: Icons.work_outline,
                                  isSelected: filters.angebotsartList.contains(
                                    '1',
                                  ),
                                  onTap: () => onAngebotsartChanged('1'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Self-Employment',
                                  icon: Icons.storefront_outlined,
                                  isSelected: filters.angebotsartList.contains(
                                    '2',
                                  ),
                                  onTap: () => onAngebotsartChanged('2'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Training',
                                  icon: Icons.school_outlined,
                                  isSelected: filters.angebotsartList.contains(
                                    '4',
                                  ),
                                  onTap: () => onAngebotsartChanged('4'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Internship',
                                  icon: Icons.trending_up_outlined,
                                  isSelected: filters.angebotsartList.contains(
                                    '34',
                                  ),
                                  onTap: () => onAngebotsartChanged('34'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Zeitarbeit (Temporary Work) Filter
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text(
                    'Temporary Work Companies',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  initiallyExpanded: false,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'Yes',
                                  icon: Icons.check_circle_outline,
                                  isSelected: filters.zeitarbeit == true,
                                  onTap: () => onZeitarbeitChanged(true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilterOptionCard(
                                  label: 'No',
                                  icon: Icons.cancel_outlined,
                                  isSelected: filters.zeitarbeit == false,
                                  onTap: () => onZeitarbeitChanged(false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Location button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.place_outlined),
                      label: const Text('Set Location'),
                      onPressed: onShowLocationDialog,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Search Jobs'),
                        onPressed: onSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
