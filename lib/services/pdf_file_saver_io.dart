import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> savePdfImpl({
  required Uint8List bytes,
  required String filename,
}) async {
  Directory baseDir;

  if (Platform.isAndroid) {
    // Save to Downloads folder for easy access
    try {
      final Directory? downloadsDir = await getExternalStorageDirectory();
      if (downloadsDir != null) {
        baseDir = downloadsDir;
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      // Fallback to app documents directory
      baseDir = await getApplicationDocumentsDirectory();
    }
  } else {
    baseDir = await getApplicationDocumentsDirectory();
  }

  if (!await baseDir.exists()) {
    await baseDir.create(recursive: true);
  }

  final path = '${baseDir.path}${Platform.pathSeparator}$filename';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
