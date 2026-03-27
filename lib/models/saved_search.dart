import 'dart:convert';

class SavedSearch {
  final String name;
  final String was;
  final String wo;
  final String berufsfeld;
  final String arbeitgeber;
  final String veroeffentlichtseit;
  final bool zeitarbeit;
  final String angebotsart;
  final String befristung;
  final String arbeitszeit;
  final double umkreis;
  final DateTime? savedAt;
  final bool isDefault;
  final bool notificationsEnabled;
  final int lastResultCount;

  SavedSearch({
    required this.name,
    this.was = '',
    this.wo = '',
    this.berufsfeld = '',
    this.arbeitgeber = '',
    this.veroeffentlichtseit = '7',
    this.zeitarbeit = false,
    this.angebotsart = '1',
    this.befristung = '2',
    this.arbeitszeit = 'vz',
    this.umkreis = 30.0,
    this.savedAt,
    this.isDefault = false,
    this.notificationsEnabled = false,
    this.lastResultCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'was': was,
      'wo': wo,
      'berufsfeld': berufsfeld,
      'arbeitgeber': arbeitgeber,
      'veroeffentlichtseit': veroeffentlichtseit,
      'zeitarbeit': zeitarbeit,
      'angebotsart': angebotsart,
      'befristung': befristung,
      'arbeitszeit': arbeitszeit,
      'umkreis': umkreis,
      'savedAt': savedAt?.toIso8601String(),
      'isDefault': isDefault,
      'notificationsEnabled': notificationsEnabled,
      'lastResultCount': lastResultCount,
    };
  }

  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      name: map['name'] ?? '',
      was: map['was'] ?? '',
      wo: map['wo'] ?? '',
      berufsfeld: map['berufsfeld'] ?? '',
      arbeitgeber: map['arbeitgeber'] ?? '',
      veroeffentlichtseit: map['veroeffentlichtseit'] ?? '7',
      zeitarbeit: map['zeitarbeit'] == true || map['zeitarbeit'] == 'true',
      angebotsart: map['angebotsart'] ?? '1',
      befristung: map['befristung'] ?? '2',
      arbeitszeit: map['arbeitszeit'] ?? 'vz',
      umkreis: (map['umkreis'] is double)
          ? map['umkreis']
          : double.tryParse(map['umkreis']?.toString() ?? '30') ?? 30.0,
      savedAt: map['savedAt'] != null ? DateTime.parse(map['savedAt']) : null,
      isDefault: map['isDefault'] == true || map['isDefault'] == 'true',
      notificationsEnabled:
          map['notificationsEnabled'] == true ||
          map['notificationsEnabled'] == 'true',
      lastResultCount: (map['lastResultCount'] is int)
          ? map['lastResultCount']
          : int.tryParse(map['lastResultCount']?.toString() ?? '0') ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedSearch.fromJson(String source) =>
      SavedSearch.fromMap(json.decode(source));
}
