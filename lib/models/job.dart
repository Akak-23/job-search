/// Represents a job posting from the API
class Job {
  final String title;
  final String description;
  final String? beruf;
  final String? arbeitgeber;
  final String? refnr;
  final String? arbeitsort;
  final String? arbeitsortStrasse;
  final String? arbeitsortPlz;
  final String? arbeitsortOrt;
  final String? arbeitsortRegion;
  final String? arbeitsortLand;
  final String? arbeitszeit;
  final String? angebotsart;
  final String? zeitarbeit;
  final String? befristung;
  final String? aktuelleVeroeffentlichungsdatum;
  final String? modifikationsTimestamp;
  final String raw;

  const Job({
    required this.title,
    required this.description,
    this.beruf,
    this.arbeitgeber,
    this.refnr,
    this.arbeitsort,
    this.arbeitsortStrasse,
    this.arbeitsortPlz,
    this.arbeitsortOrt,
    this.arbeitsortRegion,
    this.arbeitsortLand,
    this.arbeitszeit,
    this.angebotsart,
    this.zeitarbeit,
    this.befristung,
    this.aktuelleVeroeffentlichungsdatum,
    this.modifikationsTimestamp,
    required this.raw,
  });

  /// Convert Job to Map for storage
  Map<String, String> toMap() {
    final map = <String, String>{
      'title': title,
      'description': description,
      'raw': raw,
    };
    if (arbeitgeber != null) map['arbeitgeber'] = arbeitgeber!;
    if (beruf != null) map['beruf'] = beruf!;
    if (refnr != null) map['refnr'] = refnr!;
    if (arbeitsort != null) map['arbeitsort'] = arbeitsort!;
    if (arbeitsortStrasse != null) {
      map['arbeitsort_strasse'] = arbeitsortStrasse!;
    }
    if (arbeitsortPlz != null) map['arbeitsort_plz'] = arbeitsortPlz!;
    if (arbeitsortOrt != null) map['arbeitsort_ort'] = arbeitsortOrt!;
    if (arbeitsortRegion != null) map['arbeitsort_region'] = arbeitsortRegion!;
    if (arbeitsortLand != null) map['arbeitsort_land'] = arbeitsortLand!;
    if (arbeitszeit != null) map['arbeitszeit'] = arbeitszeit!;
    if (angebotsart != null) map['angebotsart'] = angebotsart!;
    if (zeitarbeit != null) map['zeitarbeit'] = zeitarbeit!;
    if (befristung != null) map['befristung'] = befristung!;
    if (aktuelleVeroeffentlichungsdatum != null) {
      map['aktuelleVeroeffentlichungsdatum'] = aktuelleVeroeffentlichungsdatum!;
    }
    if (modifikationsTimestamp != null) {
      map['modifikationsTimestamp'] = modifikationsTimestamp!;
    }
    return map;
  }

  /// Create Job from Map
  factory Job.fromMap(Map<String, String> map) {
    String? beruf;
    String? titel;
    
    // Extract beruf and titel from raw JSON
    try {
      if (map.containsKey('raw') && map['raw']!.isNotEmpty) {
        final jsonStr = map['raw']!;
        if (jsonStr.contains('"beruf"')) {
          final berufsMatch = RegExp(
            r'"beruf"\s*:\s*"([^"]+)"',
          ).firstMatch(jsonStr);
          if (berufsMatch != null) {
            beruf = berufsMatch.group(1);
          }
        }
        if (jsonStr.contains('"titel"')) {
          final titelMatch = RegExp(
            r'"titel"\s*:\s*"([^"]+)"',
          ).firstMatch(jsonStr);
          if (titelMatch != null) {
            titel = titelMatch.group(1);
          }
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }

    return Job(
      title: titel ?? map['title'] ?? 'Unnamed Job',
      description: map['description'] ?? '',
      beruf: beruf ?? map['beruf'],
      arbeitgeber: map['arbeitgeber'],
      refnr: map['refnr'],
      arbeitsort: map['arbeitsort'],
      arbeitsortStrasse: map['arbeitsort_strasse'],
      arbeitsortPlz: map['arbeitsort_plz'],
      arbeitsortOrt: map['arbeitsort_ort'],
      arbeitsortRegion: map['arbeitsort_region'],
      arbeitsortLand: map['arbeitsort_land'],
      arbeitszeit: map['arbeitszeit'],
      angebotsart: map['angebotsart'],
      zeitarbeit: map['zeitarbeit'],
      befristung: map['befristung'],
      aktuelleVeroeffentlichungsdatum: map['aktuelleVeroeffentlichungsdatum'],
      modifikationsTimestamp: map['modifikationsTimestamp'],
      raw: map['raw'] ?? '{}',
    );
  }

  /// Get full address as string
  String getFullAddress() {
    final parts = <String>[
      if (arbeitsortStrasse != null) arbeitsortStrasse!,
      if (arbeitsortPlz != null && arbeitsortOrt != null)
        '${arbeitsortPlz!} ${arbeitsortOrt!}',
      if (arbeitsortRegion != null) arbeitsortRegion!,
      if (arbeitsortLand != null) arbeitsortLand!,
    ];
    return parts.join(', ');
  }

  /// Get short location (city)
  String getShortLocation() {
    return arbeitsortOrt ?? arbeitsort ?? 'Location unknown';
  }

  @override
  String toString() => 'Job(title: $title, company: $arbeitgeber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job &&
          runtimeType == other.runtimeType &&
          refnr == other.refnr;

  @override
  int get hashCode => refnr?.hashCode ?? 0;
}
