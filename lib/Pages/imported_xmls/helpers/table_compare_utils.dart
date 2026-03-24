import 'dart:convert';
/// Utilitários para comparar revisões em formato de tabela (leigo).

String compareCellStr(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return jsonEncode(v);
}

/// Lista de linhas (cada mapa = uma linha da “tabela”), valores como texto.
List<Map<String, String>> parseJsonToTableRows(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  try {
    final d = jsonDecode(raw);
    return _normalizeToRows(d);
  } catch (_) {
    final s = raw.trim();
    return [
      {
        'Erro': 'JSON inválido',
        'Trecho': s.length > 200 ? '${s.substring(0, 200)}…' : s,
      },
    ];
  }
}

List<Map<String, String>> _normalizeToRows(dynamic d) {
  if (d is List) {
    final out = <Map<String, String>>[];
    for (var i = 0; i < d.length; i++) {
      final e = d[i];
      if (e is Map) {
        final m = <String, String>{};
        Map<String, dynamic>.from(e).forEach((k, v) {
          m[k] = compareCellStr(v);
        });
        m['#'] = '${i + 1}';
        out.add(m);
      } else {
        out.add({'#': '${i + 1}', 'valor': compareCellStr(e)});
      }
    }
    return out;
  }
  if (d is Map<String, dynamic>) {
    return _flattenMapToKeyValueRows(d);
  }
  return [{'valor': compareCellStr(d)}];
}

/// Uma linha por campo (chave com notação a.b), para comparar dois JSON “objeto”.
List<Map<String, String>> _flattenMapToKeyValueRows(
  Map<String, dynamic> map, [
  String prefix = '',
]) {
  final rows = <Map<String, String>>[];
  map.forEach((k, v) {
    final path = prefix.isEmpty ? k : '$prefix.$k';
    if (v == null) {
      rows.add({'Campo': path, 'Valor': ''});
    } else if (v is Map<String, dynamic>) {
      rows.addAll(_flattenMapToKeyValueRows(v, path));
    } else if (v is List) {
      rows.add({
        'Campo': path,
        'Valor': '[lista com ${v.length} item(ns)]',
      });
    } else {
      rows.add({'Campo': path, 'Valor': compareCellStr(v)});
    }
  });
  return rows;
}

/// Mapa campo → valor para diff lado a lado.
Map<String, String> jsonStringToFlatFieldMap(String? raw) {
  if (raw == null || raw.trim().isEmpty) return {};
  try {
    final d = jsonDecode(raw);
    if (d is Map<String, dynamic>) {
      final rows = _flattenMapToKeyValueRows(d);
      return {for (final r in rows) r['Campo']!: r['Valor']!};
    }
    if (d is List) {
      return {'conteúdo': compareCellStr(d)};
    }
    return {'conteúdo': compareCellStr(d)};
  } catch (_) {
    return {};
  }
}

List<String> orderedColumnKeys(
  List<Map<String, String>> rowsA,
  List<Map<String, String>> rowsB,
) {
  final s = <String>{};
  for (final m in rowsA) {
    s.addAll(m.keys);
  }
  for (final m in rowsB) {
    s.addAll(m.keys);
  }
  final hasLine = s.contains('#');
  s.remove('#');
  final rest = s.toList()..sort();
  if (hasLine) return ['#', ...rest];
  return rest;
}
