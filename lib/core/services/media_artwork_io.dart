import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<Uri?> cacheMediaArtwork(String assetPath) async {
  try {
    final data = await rootBundle.load(assetPath);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final directory = await getApplicationSupportDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}wudase_media_artwork.png',
    );

    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.uri;
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Media artwork could not be cached: $error');
    }
    return null;
  }
}
