// #region agent log
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// NDJSON para sessão de debug (workspace).
void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, dynamic>? data,
  String runId = 'pre-fix',
}) {
  try {
    final line = jsonEncode({
      'sessionId': 'e71ee3',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'hypothesisId': hypothesisId,
      'runId': runId,
      'data': data ?? <String, dynamic>{},
    });
    final path = p.join(Directory.current.path, 'debug-e71ee3.log');
    File(path).writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  } catch (_) {}
}
// #endregion
