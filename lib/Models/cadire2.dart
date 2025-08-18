import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Cadire2 {
  int cadinfcont;
  String cadinfprod;
  int cadinfseq;
  String cadinfdes;
  String cadinfinf;
  Cadire2({
    required this.cadinfcont,
    required this.cadinfprod,
    required this.cadinfseq,
    required this.cadinfdes,
    required this.cadinfinf,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cadinfcont': cadinfcont,
      'cadinfprod': cadinfprod,
      'cadinfseq': cadinfseq,
      'cadinfdes': cadinfdes,
      'cadinfinf': cadinfinf,
    };
  }

  factory Cadire2.fromMap(Map<String, dynamic> map) {
    return Cadire2(
      cadinfcont: map['cadinfcont'] as int,
      cadinfprod: map['cadinfprod'] as String,
      cadinfseq: map['cadinfseq'] as int,
      cadinfdes: map['cadinfdes'] as String,
      cadinfinf: map['cadinfinf'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Cadire2.fromJson(String source) =>
      Cadire2.fromMap(json.decode(source) as Map<String, dynamic>);
}
