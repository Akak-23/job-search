import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';

/// Service for parsing job API responses
class JobParsingService {
  static Future<List<Map<String, String>>> parseJobResponse(
    dynamic jsonBody,
  ) async {
    List<dynamic> list = [];

    if (jsonBody is Map<String, dynamic> &&
        jsonBody['stellenangebote'] is List) {
      list = jsonBody['stellenangebote'] as List<dynamic>;
    } else {
      list = _findFirstList(jsonBody) ?? [];
    }

    // Run parsing on isolate to prevent blocking main thread
    return compute(_parseJobsInIsolate, list);
  }

  // Top-level function for compute()
  static List<Map<String, String>> _parseJobsInIsolate(List<dynamic> list) {
    return list
        .map<Map<String, String>?>(_parseJobEntry)
        .whereType<Map<String, String>>()
        .toList();
  }

  static Map<String, String>? _parseJobEntry(dynamic e) {
    if (e is! Map<String, dynamic>) {
      // Skip entries that are not job maps to avoid fake placeholder cards
      return null;
    }

    // Extrahiere titel und beruf separat
    final titel = e['titel']?.toString();
    final beruf = e['beruf']?.toString();

    final arbeitsortMap = e['arbeitsort'];
    final hasArbeitsort = arbeitsortMap is Map<String, dynamic> &&
      (_nonEmpty(arbeitsortMap[strasse]) ||
        _nonEmpty(arbeitsortMap[plz]) ||
        _nonEmpty(arbeitsortMap[ort]) ||
        _nonEmpty(arbeitsortMap[region]) ||
        _nonEmpty(arbeitsortMap[land]) ||
        _nonEmpty(arbeitsortMap['bundesland']) ||
        _nonEmpty(arbeitsortMap['staat']));

    final hasCoreInfo = _nonEmpty(titel) ||
      _nonEmpty(beruf) ||
      _nonEmpty(e['arbeitgeber']) ||
      _nonEmpty(e['refnr']) ||
      _nonEmpty(e['beschreibung']) ||
      hasArbeitsort;

    if (!hasCoreInfo) return null;

    // Verwende titel als title, wenn vorhanden, sonst beruf, sonst fallback
    final title = titel ?? beruf ?? 'Unbenannter Job';

    final buffer = StringBuffer();
    final Map<String, String> result = {'title': title};

    // Speichere beruf separat, wenn vorhanden
    if (beruf != null && beruf.isNotEmpty) {
      result['beruf'] = beruf;
    }

    String? arbeitgeber;
    if (_nonEmpty(e['arbeitgeber'])) {
      arbeitgeber = e['arbeitgeber'].toString();
      buffer.writeln('Arbeitgeber: $arbeitgeber');
    }

    String? refnr;
    if (_nonEmpty(e['refnr'])) {
      refnr = e['refnr'].toString();
      buffer.writeln('Ref: $refnr');
    }

    String? arbeitsortStr;
    if (e['arbeitsort'] is Map<String, dynamic>) {
      final ao = e['arbeitsort'] as Map<String, dynamic>;
      final parts = <String>[];

      if (_nonEmpty(ao[strasse])) parts.add(ao[strasse].toString());
      if (_nonEmpty(ao[plz])) parts.add(ao[plz].toString());
      if (_nonEmpty(ao[ort])) parts.add(ao[ort].toString());

      if (parts.isNotEmpty) {
        arbeitsortStr = parts.join(', ');
        buffer.writeln('Arbeitsort: $arbeitsortStr');
      }

      final strasseVal = _stringValue(ao[strasse]);
      final plzVal = _stringValue(ao[plz]);
      final ortVal = _stringValue(ao[ort]);

      String? regionVal;
      if (ao.containsKey(region)) regionVal = _stringValue(ao[region]);
      regionVal ??= _stringValue(ao['bundesland']);

      String? landVal;
      if (ao.containsKey(land)) landVal = _stringValue(ao[land]);
      landVal ??= _stringValue(ao['staat']);

      if (strasseVal != null) result[arbeitsortStrasse] = strasseVal;
      if (plzVal != null) result[arbeitsortPlz] = plzVal;
      if (ortVal != null) result[arbeitsortOrt] = ortVal;
      if (regionVal != null) result[arbeitsortRegion] = regionVal;
      if (landVal != null) result[arbeitsortLand] = landVal;
    }

    String? arbeitszeit;
    if (e['arbeitszeitmodelle'] is List) {
      final models = (e['arbeitszeitmodelle'] as List)
          .whereType<dynamic>()
          .map((m) {
            if (m is Map<String, dynamic>) {
              final code = m['code'] ?? m['schluessel'] ?? m['wert'];
              final label = m['bezeichnung'] ?? m['beschreibung'] ?? m['text'];
              return _stringValue(code ?? label);
            }
            return m.toString();
          })
          .where((m) => m != null && m.trim().isNotEmpty)
          .map((m) => m!.toLowerCase())
          .toList();
      if (models.isNotEmpty) {
        arbeitszeit = models.join(';');
        buffer.writeln('Arbeitszeit: $arbeitszeit');
      }
    } else if (_nonEmpty(e['arbeitszeit'])) {
      final v = e['arbeitszeit'];
      if (v is Map<String, dynamic>) {
        final code = v['code'] ?? v['schluessel'] ?? v['wert'];
        final label = v['bezeichnung'] ?? v['text'];
        arbeitszeit = _stringValue(code ?? label);
      } else {
        arbeitszeit = v.toString();
      }
      buffer.writeln('Arbeitszeit: $arbeitszeit');
    }

    String? angebotsart;
    if (_nonEmpty(e['angebotsart'])) {
      final v = e['angebotsart'];
      if (v is Map<String, dynamic>) {
        final code = v['code'] ?? v['schluessel'] ?? v['wert'];
        final label = v['bezeichnung'] ?? v['text'];
        angebotsart = _stringValue(code ?? label);
      } else {
        angebotsart = v.toString();
      }
      buffer.writeln('Angebotsart: $angebotsart');
    }

    String? zeitarbeit;
    if (_nonEmpty(e['zeitarbeit'])) {
      final v = e['zeitarbeit'];
      if (v is bool) {
        zeitarbeit = v ? 'true' : 'false';
      } else {
        zeitarbeit = v.toString();
      }
      buffer.writeln('Zeitarbeit: $zeitarbeit');
    }

    String? befristung;
    if (_nonEmpty(e['befristung'])) {
      final v = e['befristung'];
      if (v is Map<String, dynamic>) {
        final code = v['code'] ?? v['schluessel'] ?? v['wert'];
        final label = v['bezeichnung'] ?? v['text'];
        befristung = _stringValue(code ?? label);
      } else {
        befristung = v.toString();
      }
      buffer.writeln('Befristung: $befristung');
    }

    String? published;
    if (_nonEmpty(e['aktuelleVeroeffentlichungsdatum'])) {
      published = _stringValue(e['aktuelleVeroeffentlichungsdatum']);
      if (published != null && published.isNotEmpty) {
        buffer.writeln('Veröffentlicht: $published');
      }
    }

    String? modified;
    if (_nonEmpty(e['modifikationsTimestamp'])) {
      modified = e['modifikationsTimestamp'].toString();
      buffer.writeln('Geändert: $modified');
    }

    final description = buffer.isEmpty ? json.encode(e) : buffer.toString();

    result['description'] = description;
    if (arbeitgeber != null) result['arbeitgeber'] = arbeitgeber;
    if (refnr != null) result['refnr'] = refnr;
    if (arbeitsortStr != null) result['arbeitsort'] = arbeitsortStr;
    if (arbeitszeit != null) result['arbeitszeit'] = arbeitszeit;
    if (angebotsart != null) result['angebotsart'] = angebotsart;
    if (zeitarbeit != null) result['zeitarbeit'] = zeitarbeit;
    if (befristung != null) result['befristung'] = befristung;
    if (published != null) {
      result['aktuelleVeroeffentlichungsdatum'] = published;
    }
    if (modified != null) result['modifikationsTimestamp'] = modified;
    result['raw'] = json.encode(e);

    return result;
  }

  static List<dynamic>? _findFirstList(dynamic node) {
    if (node is List) return node;
    if (node is Map<String, dynamic>) {
      for (final value in node.values) {
        final found = _findFirstList(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  static bool _nonEmpty(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is Map) return v.isNotEmpty;
    if (v is Iterable) return v.isNotEmpty;
    return true;
  }

  static String? _stringValue(dynamic v) {
    if (!_nonEmpty(v)) return null;
    return v.toString();
  }
}
