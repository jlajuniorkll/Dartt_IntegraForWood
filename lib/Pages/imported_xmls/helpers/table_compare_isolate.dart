import 'dart:isolate';

import 'package:dartt_integraforwood/Pages/imported_xmls/helpers/table_compare_utils.dart';

/// Dados pré-computados para diff de linhas (parse JSON fora do isolate principal quando grande).
class ListRowsDiffData {
  ListRowsDiffData({
    required this.rowsA,
    required this.rowsB,
    required this.cols,
  });

  final List<Map<String, String>> rowsA;
  final List<Map<String, String>> rowsB;
  final List<String> cols;
}

/// Dados pré-computados para diff achatado.
class FlatFieldDiffData {
  FlatFieldDiffData({
    required this.mapA,
    required this.mapB,
    required this.keys,
  });

  final Map<String, String> mapA;
  final Map<String, String> mapB;
  final List<String> keys;
}

ListRowsDiffData _computeListRowsDiff(List<String> pair) {
  final rawA = pair[0].isEmpty ? null : pair[0];
  final rawB = pair[1].isEmpty ? null : pair[1];
  final rowsA = parseJsonToTableRows(rawA);
  final rowsB = parseJsonToTableRows(rawB);
  final cols = orderedColumnKeys(rowsA, rowsB);
  return ListRowsDiffData(rowsA: rowsA, rowsB: rowsB, cols: cols);
}

FlatFieldDiffData _computeFlatFieldDiff(List<String> pair) {
  final rawA = pair[0].isEmpty ? null : pair[0];
  final rawB = pair[1].isEmpty ? null : pair[1];
  final mapA = jsonStringToFlatFieldMap(rawA);
  final mapB = jsonStringToFlatFieldMap(rawB);
  final keys = {...mapA.keys, ...mapB.keys}.toList()..sort();
  return FlatFieldDiffData(mapA: mapA, mapB: mapB, keys: keys);
}

const int _kJsonIsolateThresholdChars = 24000;

Future<ListRowsDiffData> computeListRowsDiffAsync(String? rawA, String? rawB) async {
  final a = rawA ?? '';
  final b = rawB ?? '';
  final pair = <String>[a, b];
  if (a.length + b.length < _kJsonIsolateThresholdChars) {
    return _computeListRowsDiff(pair);
  }
  return Isolate.run(() => _computeListRowsDiff(pair));
}

Future<FlatFieldDiffData> computeFlatFieldDiffAsync(String? rawA, String? rawB) async {
  final a = rawA ?? '';
  final b = rawB ?? '';
  final pair = <String>[a, b];
  if (a.length + b.length < _kJsonIsolateThresholdChars) {
    return _computeFlatFieldDiff(pair);
  }
  return Isolate.run(() => _computeFlatFieldDiff(pair));
}
