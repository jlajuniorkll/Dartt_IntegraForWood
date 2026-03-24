import 'package:xml/xml.dart';

/// Top-level for [Isolate.run]. Conta elementos de `RIGHE` (mesma lógica que o loader).
int xmlRigheItemCountForProgress(String xmlString) {
  final preParsed = XmlDocument.parse(xmlString);
  final righes = preParsed.findAllElements('RIGHE').toList();
  if (righes.isEmpty) return 0;
  return righes.first.children.whereType<XmlElement>().length;
}
