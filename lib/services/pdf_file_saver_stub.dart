import 'dart:typed_data';

Future<String> savePdfImpl({
  required Uint8List bytes,
  required String filename,
}) {
  throw UnsupportedError('Saving PDF is not supported on this platform');
}
