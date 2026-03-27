import 'dart:typed_data';

Future<String> savePdfImpl({
  required Uint8List bytes,
  required String filename,
}) async {
  throw UnsupportedError('PDF export is not supported on web.');
}
