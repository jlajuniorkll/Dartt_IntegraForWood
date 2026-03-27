import 'dart:io';

import 'package:dartt_integraforwood/services/app_logger.dart';

/// Lê [conf.ini] na pasta do executável (desktop) e expõe [cadiretaCadsuscad] = `user` + `3CAD`.
class ConfIniService {
  ConfIniService._();

  static String _rawUser = '';
  static bool _loaded = false;

  /// Valor para o campo `cadsuscad` na cadireta: nome do utilizador + `3CAD`, ou `IMP3CAD` se não houver [user].
  static String get cadiretaCadsuscad {
    final u = _rawUser.trim();
    if (u.isEmpty) return 'IMP3CAD';
    return '${u}3CAD';
  }

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final baseDir = _applicationRootDir();
      final f = File('$baseDir${Platform.pathSeparator}conf.ini');
      if (!await f.exists()) {
        AppLogger.i('Conf', 'conf.ini não encontrado em $baseDir');
        return;
      }
      final content = await f.readAsString();
      final parsed = _parseUserValue(content);
      _rawUser = parsed ?? '';
      if (_rawUser.isEmpty) {
        AppLogger.i('Conf', 'conf.ini sem user= (usa IMP3CAD em cadsuscad)');
      } else {
        AppLogger.i('Conf', 'conf.ini user carregado para cadsuscad');
      }
    } catch (e) {
      AppLogger.w('Conf', 'Falha ao ler conf.ini: $e');
      _rawUser = '';
    }
  }

  static String _applicationRootDir() {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return File(Platform.resolvedExecutable).parent.path;
      }
    } catch (_) {}
    return Directory.current.path;
  }

  /// Aceita `user="nome"` ou `user=nome` (linhas `;` / `#` ignoradas).
  static String? _parseUserValue(String content) {
    for (final raw in content.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty ||
          line.startsWith(';') ||
          line.startsWith('#')) {
        continue;
      }
      final m = RegExp(
        r'^user\s*=\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (m == null) continue;
      var v = m.group(1)!.trim();
      if (v.length >= 2) {
        final q0 = v.codeUnitAt(0);
        final q1 = v.codeUnitAt(v.length - 1);
        if ((q0 == 0x22 && q1 == 0x22) || (q0 == 0x27 && q1 == 0x27)) {
          v = v.substring(1, v.length - 1).trim();
        }
      }
      return v.isEmpty ? null : v;
    }
    return null;
  }
}
