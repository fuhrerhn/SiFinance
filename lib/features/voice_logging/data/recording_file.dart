import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> createRecordingPath() async {
  final directory = await getTemporaryDirectory();
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  return '${directory.path}${Platform.pathSeparator}sifinance-voice-$timestamp.wav';
}

Future<void> deleteRecording(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
