import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Cadire2 {
  int cadinfcont;
  String cadinfprod;
  int cadinfseq;
  String cadinfdes;
  String cadinfinf;
  String? nomePRG1; // Adicionar campos para PRG1 e PRG2
  String? nomePRG2;
  int? cadfase;
  String? cadmatricula;
  double? cadespessura;
  double? cadcomprimento;
  double? cadlargura;
  
  Cadire2({
    required this.cadinfcont,
    required this.cadinfprod,
    required this.cadinfseq,
    required this.cadinfdes,
    required this.cadinfinf,
    this.nomePRG1,
    this.nomePRG2,
    this.cadfase,
    this.cadmatricula,
    this.cadespessura,
    this.cadcomprimento,
    this.cadlargura,
  });

  // Adicionar método copyWith
  Cadire2 copyWith({
    int? cadinfcont,
    String? cadinfprod,
    int? cadinfseq,
    String? cadinfdes,
    String? cadinfinf,
    String? nomePRG1,
    String? nomePRG2,
    int? cadfase,
    String? cadmatricula,
    double? cadespessura,
    double? cadcomprimento,
    double? cadlargura,
  }) {
    return Cadire2(
      cadinfcont: cadinfcont ?? this.cadinfcont,
      cadinfprod: cadinfprod ?? this.cadinfprod,
      cadinfseq: cadinfseq ?? this.cadinfseq,
      cadinfdes: cadinfdes ?? this.cadinfdes,
      cadinfinf: cadinfinf ?? this.cadinfinf,
      nomePRG1: nomePRG1 ?? this.nomePRG1,
      nomePRG2: nomePRG2 ?? this.nomePRG2,
      cadfase: cadfase ?? this.cadfase,
      cadmatricula: cadmatricula ?? this.cadmatricula,
      cadespessura: cadespessura ?? this.cadespessura,
      cadcomprimento: cadcomprimento ?? this.cadcomprimento,
      cadlargura: cadlargura ?? this.cadlargura,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cadinfcont': cadinfcont,
      'cadinfprod': cadinfprod,
      'cadinfseq': cadinfseq,
      'cadinfdes': cadinfdes,
      'cadinfinf': cadinfinf,
      'nomePRG1': nomePRG1,
      'nomePRG2': nomePRG2,
      'cadfase': cadfase,
      'cadmatricula': cadmatricula,
      'cadespessura': cadespessura,
      'cadcomprimento': cadcomprimento,
      'cadlargura': cadlargura,
    };
  }

  factory Cadire2.fromMap(Map<String, dynamic> map) {
    return Cadire2(
      cadinfcont: map['cadinfcont'] as int,
      cadinfprod: map['cadinfprod'] as String,
      cadinfseq: map['cadinfseq'] as int,
      cadinfdes: map['cadinfdes'] as String,
      cadinfinf: map['cadinfinf'] as String,
      nomePRG1: map['nomePRG1'] as String?,
      nomePRG2: map['nomePRG2'] as String?,
      cadfase: map['cadfase'] as int?,
      cadmatricula: map['cadmatricula'] as String?,
      cadespessura: map['cadespessura'] as double?,
      cadcomprimento: map['cadcomprimento'] as double?,
      cadlargura: map['cadlargura'] as double?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Cadire2.fromJson(String source) =>
      Cadire2.fromMap(json.decode(source) as Map<String, dynamic>);
}
