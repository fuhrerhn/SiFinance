import 'package:web/web.dart' as web;

// The browser returns a blob URL when the recorder stops.
Future<String> createRecordingPath() async => '';

Future<void> deleteRecording(String path) async =>
    web.URL.revokeObjectURL(path);
