import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../screens/in_app_browser.dart';
import 'job_location_map_dialog.dart';

/// Bottom sheet for displaying job details
class JobDetailSheet extends StatefulWidget {
  final Map<String, String> job;
  final String title;
  final bool isFavorited;
  final ValueChanged<bool> onFavoriteChanged;
  final String? refnr;

  const JobDetailSheet({
    super.key,
    required this.job,
    required this.title,
    required this.isFavorited,
    required this.onFavoriteChanged,
    this.refnr,
  });

  @override
  State<JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<JobDetailSheet> {
  int _selectedTab = 1;
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.job.entries.where((e) => e.value.trim().isNotEmpty);
    final description =
        widget.job[descriptionField] ?? widget.job['description'] ?? '';

    final arbeitsortKeys = [
      arbeitsortStrasse,
      arbeitsortPlz,
      arbeitsortOrt,
      arbeitsortRegion,
      arbeitsortLand,
    ];

    final structuredArbeitsort = <String, String>{};
    for (final k in arbeitsortKeys) {
      if (widget.job.containsKey(k) &&
          widget.job[k] != null &&
          widget.job[k]!.trim().isNotEmpty) {
        structuredArbeitsort[k] = widget.job[k]!;
      }
    }

    final displayEntries = entries.where(
      (e) =>
          !arbeitsortKeys.contains(e.key) &&
          e.key != arbeitsort &&
          e.key != arbeitgeber,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 1.0,
        minChildSize: 0.7,
        maxChildSize: 1.0,
        builder: (context, controller) {
          return Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroHeader(context),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSegmentedTabs(),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _selectedTab == 0
                            ? _buildDescriptionSection(description)
                            : _buildCompanySection(
                                structuredArbeitsort,
                                displayEntries,
                              ),
                      ),
                      const SizedBox(height: 20),
                      _buildActionButtons(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final location = _buildLocationLabel();
    final tags = _buildTagLabels();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF6C63FF),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorited = !_isFavorited;
                    });
                    widget.onFavoriteChanged(_isFavorited);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(widget.title),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              location,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: tags
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [Expanded(child: _buildTabButton('Description', 1))],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    final lines = description
        .split(RegExp(r'\n|•|-'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return Text(
        'No description provided yet.',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(color: Colors.grey[800], height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCompanySection(
    Map<String, String> structuredArbeitsort,
    Iterable<MapEntry<String, String>> displayEntries,
  ) {
    final content = <Widget>[];
    if (widget.job['arbeitgeber'] != null &&
        widget.job['arbeitgeber']!.isNotEmpty) {
      content.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.08),
                const Color(0xFF6C63FF).withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      const Color(0xFF6C63FF).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  size: 28,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.job['arbeitgeber']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3436),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (structuredArbeitsort.isNotEmpty) {
      content.add(_buildArbeitsortSection(structuredArbeitsort));
    }
    if (displayEntries.isNotEmpty) {
      content.add(_buildDetailsSection(displayEntries));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  String _buildLocationLabel() {
    final parts = <String>[];
    final ort = widget.job[arbeitsortOrt]?.trim();
    final region = widget.job[arbeitsortRegion]?.trim();
    final land = widget.job[arbeitsortLand]?.trim();
    final arbeitsortValue = widget.job[arbeitsort]?.trim();

    if (ort != null && ort.isNotEmpty && ort != boolNull) parts.add(ort);
    if (region != null &&
        region.isNotEmpty &&
        region != boolNull &&
        region != ort) {
      parts.add(region);
    }
    if (land != null && land.isNotEmpty && land != boolNull) parts.add(land);

    if (parts.isEmpty &&
        arbeitsortValue != null &&
        arbeitsortValue.isNotEmpty) {
      parts.add(arbeitsortValue);
    }

    return parts.join(' • ');
  }

  List<String> _buildTagLabels() {
    final tags = <String>[];
    final arbeitszeit = widget.job['arbeitszeit']?.trim();
    final beruf = widget.job['beruf']?.trim();
    final angebotsart = widget.job['angebotsart']?.trim();

    if (beruf != null && beruf.isNotEmpty) tags.add(beruf);
    if (arbeitszeit != null && arbeitszeit.isNotEmpty) {
      tags.add(_formatArbeitszeit(arbeitszeit));
    }
    if (angebotsart != null && angebotsart.isNotEmpty) {
      tags.add(_formatAngebotsart(angebotsart));
    }

    return tags.take(3).toList();
  }

  // Note: Unused - kept for future extension
  // Note: Unused - kept for future extension
  // ignore: unused_element
  Widget _buildQuickInfo(BuildContext context) {
    final arbeitszeit = widget.job['arbeitszeit']?.trim();
    final angebotsart = widget.job['angebotsart']?.trim();
    final zeitarbeit = widget.job['zeitarbeit']?.trim();

    final chips = <Widget>[];

    if (arbeitszeit != null && arbeitszeit.isNotEmpty) {
      chips.add(
        _buildInfoChip(
          context,
          Icons.schedule_rounded,
          _formatArbeitszeit(arbeitszeit),
          Colors.purple,
        ),
      );
    }

    if (angebotsart != null && angebotsart.isNotEmpty) {
      chips.add(
        _buildInfoChip(
          context,
          Icons.work_rounded,
          _formatAngebotsart(angebotsart),
          Colors.green,
        ),
      );
    }

    if (zeitarbeit != null &&
        zeitarbeit.isNotEmpty &&
        (zeitarbeit.toLowerCase() == boolTrue ||
            zeitarbeit.toLowerCase() == boolJa)) {
      chips.add(
        _buildInfoChip(
          context,
          Icons.access_time_rounded,
          labelZeitarbeit,
          Colors.orange,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color[900],
            ),
          ),
        ],
      ),
    );
  }

  String _formatArbeitszeit(String arbeitszeit) {
    final codes = arbeitszeit
        .split(';')
        .where((c) => c.trim().isNotEmpty)
        .toList();
    final mapped = codes.map((c) {
      switch (c.toLowerCase()) {
        case 'vz':
        case 'vollzeit':
          return 'Vollzeit';
        case 'tz':
        case 'teilzeit':
          return 'Teilzeit';
        case 'ho':
        case 'homeoffice':
          return 'Homeoffice';
        default:
          return c;
      }
    }).toList();
    return mapped.join(' · ');
  }

  String _formatAngebotsart(String angebotsart) {
    switch (angebotsart.toLowerCase()) {
      case '1':
      case 'arbeitsplatz':
        return 'Festanstellung';
      case '2':
        return 'Selbständigkeit';
      case '4':
      case 'ausbildung':
        return 'Ausbildung';
      case '34':
      case praktikum:
        return labelPraktikum;
      default:
        return angebotsart;
    }
  }

  Widget _buildDetailsSection(
    Iterable<MapEntry<String, String>> displayEntries,
  ) {
    final filteredEntries = displayEntries
        .where(
          (e) =>
              e.key != 'title' &&
              e.key != 'description' &&
              e.key != 'beruf' &&
              e.key != 'raw',
        )
        .toList();

    if (filteredEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Details',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
          ),
          ...filteredEntries.map((e) => _buildField(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildArbeitsortSection(Map<String, String> structuredArbeitsort) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Work Location',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.blue[900],
                ),
              ),
              const Spacer(),
              // Map button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLocationOnMap(structuredArbeitsort),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Map',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (structuredArbeitsort[arbeitsortStrasse] != null &&
              structuredArbeitsort[arbeitsortStrasse]!.isNotEmpty &&
              structuredArbeitsort[arbeitsortStrasse] != boolNull)
            _buildLocationItem(
              Icons.signpost_outlined,
              labelStrasse,
              structuredArbeitsort[arbeitsortStrasse]!,
            ),
          if (structuredArbeitsort[arbeitsortPlz] != null &&
              structuredArbeitsort[arbeitsortPlz]!.isNotEmpty &&
              structuredArbeitsort[arbeitsortPlz] != boolNull)
            _buildLocationItem(
              Icons.mail_outline,
              labelPlz,
              structuredArbeitsort[arbeitsortPlz]!,
            ),
          if (structuredArbeitsort[arbeitsortOrt] != null &&
              structuredArbeitsort[arbeitsortOrt]!.isNotEmpty &&
              structuredArbeitsort[arbeitsortOrt] != boolNull)
            _buildLocationItem(
              Icons.location_city_outlined,
              labelOrt,
              structuredArbeitsort[arbeitsortOrt]!,
            ),
          if (structuredArbeitsort[arbeitsortRegion] != null &&
              structuredArbeitsort[arbeitsortRegion]!.isNotEmpty &&
              structuredArbeitsort[arbeitsortRegion] != boolNull)
            _buildLocationItem(
              Icons.map_outlined,
              labelRegion,
              structuredArbeitsort[arbeitsortRegion]!,
            ),
          if (structuredArbeitsort[arbeitsortLand] != null &&
              structuredArbeitsort[arbeitsortLand]!.isNotEmpty &&
              structuredArbeitsort[arbeitsortLand] != boolNull)
            _buildLocationItem(
              Icons.public_outlined,
              labelLand,
              structuredArbeitsort[arbeitsortLand]!,
            ),
        ],
      ),
    );
  }

  void _showLocationOnMap(Map<String, String> structuredArbeitsort) {
    showDialog(
      context: context,
      builder: (context) =>
          JobLocationMapDialog(locationData: structuredArbeitsort),
    );
  }

  Widget _buildLocationItem(IconData icon, String label, String value) {
    // Ignore null strings or empty values
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty || trimmedValue == boolNull) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              trimmedValue,
              style: TextStyle(fontSize: 14, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String key, String value) {
    // Ignore null or empty values
    if (value.isEmpty || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final icon = _iconForKey(key);
    final formattedValue = _formatFieldValue(key, value);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  const Color(0xFF6C63FF).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForKey(key),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedValue,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (widget.refnr != null && widget.refnr!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 54,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => _openJobLink(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_browser_rounded, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Open Job',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openJobLink(BuildContext context) async {
    if (widget.refnr != null && widget.refnr!.isNotEmpty) {
      final url =
          'https://www.arbeitsagentur.de/jobsuche/jobdetail/${widget.refnr}';
      if (context.mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => InAppBrowser(url: url)));
      }
    }
  }

  String _labelForKey(String k) {
    switch (k) {
      case 'arbeitgeber':
        return 'Employer';
      case 'refnr':
        return 'Reference Number';
      case 'arbeitsort':
        return 'Work Location';
      case 'arbeitszeit':
        return 'Working Hours';
      case 'angebotsart':
        return 'Job Type';
      case 'zeitarbeit':
        return 'Temporary Work';
      case 'befristung':
        return 'Contract Duration';
      case 'aktuelleVeroeffentlichungsdatum':
        return 'Published On';
      case 'modifikationsTimestamp':
        return 'Last Modified';
      case 'raw':
        return 'Raw Data';
      default:
        return k;
    }
  }

  IconData _iconForKey(String k) {
    switch (k) {
      case 'arbeitgeber':
        return Icons.business_rounded;
      case 'refnr':
        return Icons.tag_rounded;
      case 'arbeitsort':
        return Icons.location_on_rounded;
      case 'arbeitszeit':
        return Icons.schedule_rounded;
      case 'angebotsart':
        return Icons.work_rounded;
      case 'zeitarbeit':
        return Icons.access_time_rounded;
      case 'befristung':
        return Icons.event_rounded;
      case 'aktuelleVeroeffentlichungsdatum':
        return Icons.calendar_today_rounded;
      case 'modifikationsTimestamp':
        return Icons.update_rounded;
      case 'raw':
        return Icons.code_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _initials(String text) {
    // Remove special characters and emojis, keep only letters
    final lettersOnly = text.replaceAll(RegExp(r'[^a-zA-ZäöüÄÖÜß]'), '');

    if (lettersOnly.isEmpty) return '??';

    // Get first two alphabetic characters
    if (lettersOnly.length >= 2) {
      return lettersOnly.substring(0, 2).toUpperCase();
    } else if (lettersOnly.length == 1) {
      return lettersOnly[0].toUpperCase();
    }

    return '??';
  }

  String _formatFieldValue(String key, String value) {
    // Check for null or empty values
    if (value.isEmpty) return 'Not specified';

    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return 'Not specified';

    // Format dates and times based on field type
    switch (key) {
      case 'aktuelleVeroeffentlichungsdatum':
      case 'modifikationsTimestamp':
        return _formatDateTime(trimmedValue);
      default:
        return trimmedValue;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      // Remove whitespace
      final trimmed = dateTimeString.trim();

      if (trimmed.isEmpty) return 'Not specified';

      // Try to parse the date
      // Support various formats
      DateTime dateTime;

      // Format: "2024-01-07T14:30:00" or similar
      if (trimmed.contains('T') || trimmed.contains(' ')) {
        dateTime = DateTime.parse(trimmed.replaceAll(' ', 'T'));
      } else if (trimmed.contains('-')) {
        // Format: "2024-01-07"
        dateTime = DateTime.parse(trimmed);
      } else if (trimmed.contains('.')) {
        // Format: "07.01.2024" or "07.01.2024 14:30"
        final parts = trimmed.split(' ');
        final dateParts = parts[0].split('.');
        if (dateParts.length == 3) {
          final day = int.tryParse(dateParts[0]);
          final month = int.tryParse(dateParts[1]);
          final year = int.tryParse(dateParts[2]);

          if (day == null || month == null || year == null) {
            return dateTimeString;
          }

          if (parts.length > 1) {
            // Time available
            final timeParts = parts[1].split(':');
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = timeParts.length > 1
                ? int.tryParse(timeParts[1]) ?? 0
                : 0;
            dateTime = DateTime(year, month, day, hour, minute);
          } else {
            dateTime = DateTime(year, month, day);
          }
        } else {
          return dateTimeString;
        }
      } else {
        return dateTimeString;
      }

      // Format date as DD.MM.YYYY
      final formattedDate =
          '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';

      // If time is available, add it as HH:MM
      if (dateTime.hour != 0 || dateTime.minute != 0) {
        final formattedTime =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        return '$formattedDate $formattedTime';
      }

      return formattedDate;
    } catch (e) {
      // If parsing fails, return the original value
      return dateTimeString;
    }
  }
}
