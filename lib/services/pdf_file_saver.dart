import 'dart:typed_data';

import 'pdf_file_saver_stub.dart'
    if (dart.library.io) 'pdf_file_saver_io.dart'
    if (dart.library.html) 'pdf_file_saver_web.dart';

Future<String> savePdf({
  required Uint8List bytes,
  required String filename,
}) {
  return savePdfImpl(bytes: bytes, filename: filename);
}
