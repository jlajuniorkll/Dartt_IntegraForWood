import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

enum AppLogLevel {
  debug,
  info,
  warning,
  error;

  String get label => name.toUpperCase();
}

class LogEntryModel {
  LogEntryModel({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  final DateTime time;
  final AppLogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;

  String get line {
    final ts = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(time);
    final buf = StringBuffer('[$ts] ${level.label} [$tag] $message');
    if (stackTrace != null && stackTrace!.trim().isNotEmpty) {
      buf.write('\n$stackTrace');
    }
    return buf.toString();
  }
}

/// Log em memória + arquivo diário em `log/system_yyyyMMdd.log`.
class AppLogger extends GetxService {
  AppLogger();

  static const int maxEntries = 8000;

  final RxList<LogEntryModel> entries = <LogEntryModel>[].obs;

  File? _file;
  String? _filePath;

  final List<String> _fileWriteBuffer = [];
  Timer? _fileFlushTimer;
  static const _fileFlushInterval = Duration(milliseconds: 280);

  String? get logFilePath => _filePath;

  void _scheduleFileFlush() {
    _fileFlushTimer ??= Timer(_fileFlushInterval, _flushFileBuffer);
  }

  void _flushFileBuffer() {
    _fileFlushTimer?.cancel();
    _fileFlushTimer = null;
    if (_file == null || _fileWriteBuffer.isEmpty) return;
    try {
      final chunk = _fileWriteBuffer.join();
      _fileWriteBuffer.clear();
      _file!.writeAsStringSync(
        chunk,
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }

  @override
  void onClose() {
    _flushFileBuffer();
    super.onClose();
  }

  Future<void> prepare() async {
    try {
      final dir = Directory(p.join(Directory.current.path, 'log'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final name =
          'system_${DateFormat('yyyyMMdd').format(DateTime.now())}.log';
      _filePath = p.join(dir.path, name);
      _file = File(_filePath!);
    } catch (_) {
      _file = null;
      _filePath = null;
    }
    logInfo('App', 'Integra3CadForWood — sessão de log iniciada');
    if (_filePath != null) {
      logDebug('App', 'Arquivo: $_filePath');
    }
  }

  void logDebug(String tag, String message) =>
      _add(LogEntryModel(
        time: DateTime.now(),
        level: AppLogLevel.debug,
        tag: tag,
        message: message,
      ));

  void logInfo(String tag, String message) =>
      _add(LogEntryModel(
        time: DateTime.now(),
        level: AppLogLevel.info,
        tag: tag,
        message: message,
      ));

  void logWarning(String tag, String message) =>
      _add(LogEntryModel(
        time: DateTime.now(),
        level: AppLogLevel.warning,
        tag: tag,
        message: message,
      ));

  void logError(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buf = StringBuffer(message);
    if (error != null) {
      buf.write(' | $error');
    }
    _add(LogEntryModel(
      time: DateTime.now(),
      level: AppLogLevel.error,
      tag: tag,
      message: buf.toString(),
      stackTrace: stackTrace?.toString(),
    ));
  }

  /// Incrementado a cada linha (para UI seguir o fim do log).
  final RxInt logVersion = 0.obs;

  void _add(LogEntryModel e) {
    entries.add(e);
    logVersion.value++;
    while (entries.length > maxEntries) {
      entries.removeAt(0);
    }
    try {
      if (_file != null) {
        _fileWriteBuffer.add('${e.line}\n');
        _scheduleFileFlush();
      }
    } catch (_) {}
  }

  void clearMemory() {
    entries.clear();
  }

  Future<void> clearTodaysFile() async {
    try {
      _flushFileBuffer();
      if (_file != null && await _file!.exists()) {
        await _file!.writeAsString('');
      }
    } catch (_) {}
  }

  String exportEntries(Iterable<LogEntryModel> items) =>
      items.map((e) => e.line).join('\n\n---\n\n');

  // --- Atalhos estáticos (quando Get já registrou o serviço) ---

  static void _run(void Function(AppLogger l) fn) {
    if (Get.isRegistered<AppLogger>()) {
      fn(Get.find<AppLogger>());
    }
  }

  static void d(String tag, String message) =>
      _run((l) => l.logDebug(tag, message));

  static void i(String tag, String message) =>
      _run((l) => l.logInfo(tag, message));

  static void w(String tag, String message) =>
      _run((l) => l.logWarning(tag, message));

  static void e(
    String tag,
    String message, {
    Object? error,
    StackTrace? stack,
  }) =>
      _run((l) => l.logError(tag, message, error: error, stackTrace: stack));
}
