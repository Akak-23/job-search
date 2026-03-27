import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import 'jobs/job_detail_sheet.dart';
import 'package:share_plus/share_plus.dart';

/// Refactored Job Card Widget with separated concerns
class JobCardRefactored extends StatefulWidget {
  final String title;
  final String description;
  final Map<String, String>? job;
  final bool isFavorited;
  final bool isApplied;
  final ValueChanged<bool>? onFavoriteChanged;
  final String? refnr;

  const JobCardRefactored({
    super.key,
    required this.title,
    required this.description,
    this.job,
    this.isFavorited = false,
    this.isApplied = false,
    this.onFavoriteChanged,
    this.refnr,
  });

  @override
  State<JobCardRefactored> createState() => _JobCardRefactoredState();
}

class _JobCardRefactoredState extends State<JobCardRefactored>
    with SingleTickerProviderStateMixin {
  late bool _isFavorited;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap card in RepaintBoundary to isolate repaints
    return RepaintBoundary(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 8),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              onTap: () {
                _scaleController.forward().then((_) {
                  _scaleController.reverse();
                });
                _showDetails();
              },
              onTapDown: (_) => _scaleController.forward(),
              onTapUp: (_) => _scaleController.reverse(),
              onTapCancel: () => _scaleController.reverse(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildAvatar(context),
                      const SizedBox(width: 16),
                      _buildContent(),
                      const SizedBox(width: 12),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(widget.title),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final location = _locationText();
    final employer = _jobValue('arbeitgeber');
    final arbeitszeit = _arbeitszeitLabel();
    final jobType = _jobTypeLabel();
    final tempWork = _temporaryWorkLabel();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(),
          const SizedBox(height: 4),
          if (employer.isNotEmpty || location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 4,
                children: [
                  if (employer.isNotEmpty)
                    _InlineInfo(icon: Icons.business_outlined, text: employer),
                  if (location.isNotEmpty)
                    _InlineInfo(icon: Icons.place_outlined, text: location),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _buildMetaChips([
            if (arbeitszeit.isNotEmpty)
              _MetaChipData(Icons.schedule, arbeitszeit),
            if (jobType.isNotEmpty) _MetaChipData(Icons.work_outline, jobType),
            if (tempWork.isNotEmpty)
              _MetaChipData(Icons.handyman_outlined, tempWork),
            _getAvailabilityChip(),
          ]),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildFavoriteButton(), _buildShareButton()],
    );
  }

  Widget _buildTitleSection() {
    final profession = _jobValue('beruf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (profession.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            profession,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: -0.2,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: IconButton(
        key: ValueKey<bool>(_isFavorited),
        icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border),
        color: _isFavorited ? Theme.of(context).colorScheme.primary : null,
        onPressed: _toggleFavorite,
      ),
    );
  }

  Widget _buildShareButton() {
    return IconButton(
      icon: const Icon(Icons.share_outlined),
      color: Colors.grey[600],
      onPressed: widget.refnr != null && widget.refnr!.isNotEmpty
          ? _shareJob
          : null,
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
      if (widget.onFavoriteChanged != null) {
        widget.onFavoriteChanged!(_isFavorited);
      }
    });
  }

  void _showDetails() {
    final Map<String, String> job =
        widget.job ??
        {'title': widget.title, 'description': widget.description};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => JobDetailSheet(
        job: job,
        title: widget.title,
        isFavorited: _isFavorited,
        onFavoriteChanged: (newValue) {
          setState(() {
            _isFavorited = newValue;
            if (widget.onFavoriteChanged != null) {
              widget.onFavoriteChanged!(newValue);
            }
          });
        },
        refnr: widget.refnr,
      ),
    );
  }

  void _shareJob() {
    if (widget.refnr != null && widget.refnr!.isNotEmpty) {
      final url =
          'https://www.arbeitsagentur.de/jobsuche/jobdetail/${widget.refnr}';
      final subject = widget.title;
      final text = 'Check out this job: ${widget.title}\n\n$url';

      Share.share(text, subject: subject);
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

  String _locationText() {
    final region = _jobValue('arbeitsort_region');
    final city = _jobValue('arbeitsort_ort');
    final parts = <String>[];
    
    if (city.trim().isNotEmpty) parts.add(city);
    if (region.trim().isNotEmpty && city.trim() != region.trim()) parts.add(region);
    
    return parts.join(' | ');
  }

  String _arbeitszeitLabel() {
    final raw = _jobValue('arbeitszeit');
    if (raw.isEmpty) return '';
    final codes = raw.split(';').where((c) => c.trim().isNotEmpty).toList();
    final mapped = codes.map((c) {
      switch (c.toLowerCase()) {
        case 'vz':
          return 'Vollzeit';
        case 'tz':
          return 'Teilzeit';
        case 'ho':
          return 'Homeoffice';
        case 'snw':
          return 'Schicht/Nacht';
        case 'vollzeit':
          return 'Vollzeit';
        case 'teilzeit':
          return 'Teilzeit';
        case 'schicht':
          return 'Schichtarbeit';
        case 'nacht':
          return 'Nachtarbeit';
        case 'hybrid':
          return 'Hybrid';
        default:
          return c.isNotEmpty
              ? c[0].toUpperCase() + c.substring(1).toLowerCase()
              : c;
      }
    }).toList();
    return mapped.join(', ');
  }

  String _jobTypeLabel() {
    final raw = _jobValue('angebotsart');
    switch (raw.toLowerCase()) {
      case '1':
        return 'Employment';
      case '2':
        return 'Self-Employment';
      case '4':
        return 'Training';
      case '34':
        return 'Internship';
      case 'arbeitsplatz':
        return 'Employment';
      case 'ausbildung':
        return 'Training';
      case praktikum:
        return 'Internship';
      default:
        return raw;
    }
  }

  String _temporaryWorkLabel() {
    final raw = _jobValue(zeitarbeit).toLowerCase();
    if (raw.isEmpty) return '';
    if (raw == boolTrue || raw == boolOne || raw == boolJa) {
      return labelZeitarbeit;
    }
    if (raw == boolFalse || raw == boolZero || raw == boolNein) {
      return labelKeineZeitarbeit;
    }
    return raw;
  }

  String _jobValue(String key) {
    return widget.job?[key]?.trim() ?? '';
  }

  _MetaChipData? _getAvailabilityChip() {
    final publishedDate = _jobValue('aktuelleVeroeffentlichungsdatum');
    if (publishedDate.isEmpty) return null;

    final availabilityText = _formatAvailability(publishedDate);
    if (availabilityText == null) return null;

    return _MetaChipData(Icons.access_time_rounded, availabilityText);
  }

  String? _formatAvailability(String dateString) {
    try {
      final trimmed = dateString.trim();
      if (trimmed.isEmpty) return null;

      DateTime publishedDate;

      // Versuche verschiedene Datumsformate zu parsen
      if (trimmed.contains('T') || trimmed.contains(' ')) {
        publishedDate = DateTime.parse(trimmed.replaceAll(' ', 'T'));
      } else if (trimmed.contains('-')) {
        publishedDate = DateTime.parse(trimmed);
      } else if (trimmed.contains('.')) {
        final parts = trimmed.split(' ');
        final dateParts = parts[0].split('.');
        if (dateParts.length == 3) {
          final day = int.tryParse(dateParts[0]);
          final month = int.tryParse(dateParts[1]);
          final year = int.tryParse(dateParts[2]);

          if (day == null || month == null || year == null) return null;

          if (parts.length > 1) {
            final timeParts = parts[1].split(':');
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = timeParts.length > 1
                ? int.tryParse(timeParts[1]) ?? 0
                : 0;
            publishedDate = DateTime(year, month, day, hour, minute);
          } else {
            publishedDate = DateTime(year, month, day);
          }
        } else {
          return null;
        }
      } else {
        return null;
      }

      // Berechne die verstrichene Zeit
      final now = DateTime.now();
      final difference = now.difference(publishedDate);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return 'vor $years ${years == 1 ? 'Jahr' : 'Jahren'}';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return 'vor $months ${months == 1 ? 'Monat' : 'Monaten'}';
      } else if (difference.inDays > 0) {
        return 'vor ${difference.inDays} ${difference.inDays == 1 ? 'Tag' : 'Tagen'}';
      } else if (difference.inHours > 0) {
        return 'vor ${difference.inHours} ${difference.inHours == 1 ? 'Stunde' : 'Stunden'}';
      } else if (difference.inMinutes > 0) {
        return 'vor ${difference.inMinutes} ${difference.inMinutes == 1 ? 'Minute' : 'Minuten'}';
      } else {
        return 'gerade eben';
      }
    } catch (e) {
      return null;
    }
  }

  Widget _buildMetaChips(List<_MetaChipData?> chips) {
    final filteredChips = chips.whereType<_MetaChipData>().toList();
    if (filteredChips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filteredChips
          .map((c) => _MetaChip(icon: c.icon, label: c.label))
          .toList(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChipData {
  final IconData icon;
  final String label;

  const _MetaChipData(this.icon, this.label);
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey[700]),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}
