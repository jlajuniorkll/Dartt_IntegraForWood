import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Cadiredi {
  int cadcont;
  String cadpai;
  String cadfilho;
  int caddseq;
  double caddcom;
  double caddlar;
  double caddesp;
  double caddcob;
  double caddlab;
  double caddesb;
  String cadcor;
  String caddbint;
  String caddbsup;
  String caddbinf;
  String caddbesq;
  String caddbdir;
  String caddpdes;
  double? caddper;
  int? caddqtd;
  Cadiredi({
    required this.cadcont,
    required this.cadpai,
    required this.cadfilho,
    required this.caddseq,
    required this.caddcom,
    required this.caddlar,
    required this.caddesp,
    required this.caddcob,
    required this.caddlab,
    required this.caddesb,
    required this.cadcor,
    required this.caddbint,
    required this.caddbsup,
    required this.caddbinf,
    required this.caddbesq,
    required this.caddbdir,
    required this.caddpdes,
    this.caddper =
        9.99, // TODO: // valor padrão 0.00 foi feito isso apenas para deletar registros do database
    this.caddqtd = 1,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cadcont': cadcont,
      'cadpai': cadpai,
      'cadfilho': cadfilho,
      'caddseq': caddseq,
      'caddcom': caddcom,
      'caddlar': caddlar,
      'caddesp': caddesp,
      'caddcob': caddcob,
      'caddlab': caddlab,
      'caddesb': caddesb,
      'cadcor': cadcor,
      'caddbint': caddbint,
      'caddbsup': caddbsup,
      'caddbinf': caddbinf,
      'caddbesq': caddbesq,
      'caddbdir': caddbdir,
      'caddpdes': caddpdes,
      'caddper': caddper,
      'caddqtd': caddqtd,
    };
  }

  factory Cadiredi.fromMap(Map<String, dynamic> map) {
    return Cadiredi(
      cadcont: map['cadcont'] as int,
      cadpai: map['cadpai'] as String,
      cadfilho: map['cadfilho'] as String,
      caddseq: map['caddseq'] as int,
      caddcom: map['caddcom'] as double,
      caddlar: map['caddlar'] as double,
      caddesp: map['caddesp'] as double,
      caddcob: map['caddcob'] as double,
      caddlab: map['caddlab'] as double,
      caddesb: map['caddesb'] as double,
      cadcor: map['cadcor'] as String,
      caddbint: map['caddbint'] as String,
      caddbsup: map['caddbsup'] as String,
      caddbinf: map['caddbinf'] as String,
      caddbesq: map['caddbesq'] as String,
      caddbdir: map['caddbdir'] as String,
      caddpdes: map['caddpdes'] as String,
      caddper: map['caddper'] != null ? map['caddper'] as double : null,
      caddqtd: map['caddqtd'] != null ? map['caddqtd'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Cadiredi.fromJson(String source) =>
      Cadiredi.fromMap(json.decode(source) as Map<String, dynamic>);
}
