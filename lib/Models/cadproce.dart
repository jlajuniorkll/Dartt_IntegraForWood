import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Cadproce {
  int cadcont;
  String cadpprod;
  String cadpprce;
  String cadpoper;
  String cadpmaqu;
  int cadpfase;
  double cadpnrep;
  double cadphora;
  String cadpulfa;
  Cadproce({
    required this.cadcont,
    required this.cadpprod,
    required this.cadpprce,
    required this.cadpoper,
    required this.cadpmaqu,
    required this.cadpfase,
    required this.cadpnrep,
    required this.cadphora,
    required this.cadpulfa,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cadcont': cadcont,
      'cadpprod': cadpprod,
      'cadpprce': cadpprce,
      'cadpoper': cadpoper,
      'cadpmaqu': cadpmaqu,
      'cadpfase': cadpfase,
      'cadpnrep': cadpnrep,
      'cadphora': cadphora,
      'cadpulfa': cadpulfa,
    };
  }

  factory Cadproce.fromMap(Map<String, dynamic> map) {
    return Cadproce(
      cadcont: map['cadcont'] as int,
      cadpprod: map['cadpprod'] as String,
      cadpprce: map['cadpprce'] as String,
      cadpoper: map['cadpoper'] as String,
      cadpmaqu: map['cadpmaqu'] as String,
      cadpfase: map['cadpfase'] as int,
      cadpnrep: map['cadpnrep'] as double,
      cadphora: map['cadphora'] as double,
      cadpulfa: map['cadpulfa'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Cadproce.fromJson(String source) =>
      Cadproce.fromMap(json.decode(source) as Map<String, dynamic>);
}
