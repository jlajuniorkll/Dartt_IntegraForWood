import 'dart:convert';

class XmlImportado {
  int? id;
  String numero;
  int revisao; // Novo campo para controle de versões
  String rif;
  String pai;
  String data;
  String? numeroFabricacao;
  String
  status; // 'aguardando', 'orcado', 'produzir', 'em_producao', 'finalizado'
  String? jsonCadiredi;
  String? jsonCadireta;
  String? jsonCadproce;
  String? jsonOutlite;
  DateTime createdAt;
  DateTime? updatedAt;

  XmlImportado({
    this.id,
    required this.numero,
    this.revisao = 1, // Valor padrão para nova revisão
    required this.rif,
    required this.pai,
    required this.data,
    this.numeroFabricacao,
    this.status = 'aguardando',
    this.jsonCadiredi,
    this.jsonCadireta,
    this.jsonCadproce,
    this.jsonOutlite,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'revisao': revisao,
      'rif': rif,
      'pai': pai,
      'data': data,
      'numeroFabricacao': numeroFabricacao,
      'status': status,
      'jsonCadiredi': jsonCadiredi,
      'jsonCadireta': jsonCadireta,
      'jsonCadproce': jsonCadproce,
      'jsonOutlite': jsonOutlite,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Novo método para UPDATE (sem o campo id)
  Map<String, dynamic> toMapForUpdate() {
    return {
      'numero': numero,
      'revisao': revisao,
      'rif': rif,
      'pai': pai,
      'data': data,
      'numeroFabricacao': numeroFabricacao,
      'status': status,
      'jsonCadiredi': jsonCadiredi,
      'jsonCadireta': jsonCadireta,
      'jsonCadproce': jsonCadproce,
      'jsonOutlite': jsonOutlite,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory XmlImportado.fromMap(Map<String, dynamic> map) {
    return XmlImportado(
      id: map['id']?.toInt(),
      numero: map['numero'] ?? '',
      revisao: map['revisao']?.toInt() ?? 1,
      rif: map['rif'] ?? '',
      pai: map['pai'] ?? '',
      data: map['data'] ?? '',
      numeroFabricacao: map['numeroFabricacao'],
      status: map['status'] ?? 'aguardando',
      jsonCadiredi: map['jsonCadiredi'],
      jsonCadireta: map['jsonCadireta'],
      jsonCadproce: map['jsonCadproce'],
      jsonOutlite: map['jsonOutlite'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory XmlImportado.fromJson(String source) =>
      XmlImportado.fromMap(json.decode(source));

  XmlImportado copyWith({
    int? id,
    String? numero,
    int? revisao,
    String? rif,
    String? pai,
    String? data,
    String? numeroFabricacao,
    String? status,
    String? jsonCadiredi,
    String? jsonCadireta,
    String? jsonCadproce,
    String? jsonOutlite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return XmlImportado(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      revisao: revisao ?? this.revisao,
      rif: rif ?? this.rif,
      pai: pai ?? this.pai,
      data: data ?? this.data,
      numeroFabricacao: numeroFabricacao ?? this.numeroFabricacao,
      status: status ?? this.status,
      jsonCadiredi: jsonCadiredi ?? this.jsonCadiredi,
      jsonCadireta: jsonCadireta ?? this.jsonCadireta,
      jsonCadproce: jsonCadproce ?? this.jsonCadproce,
      jsonOutlite: jsonOutlite ?? this.jsonOutlite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Enum para status do XML
enum StatusXml {
  aguardando('aguardando', 'Aguardando'),
  orcado('orcado', 'Orçado'),
  produzir('produzir', 'Produzir'),
  emProducao('em_producao', 'Em produção'),
  finalizado('finalizado', 'Finalizado');

  const StatusXml(this.value, this.label);
  final String value;
  final String label;

  static StatusXml fromValue(String value) {
    return StatusXml.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StatusXml.aguardando,
    );
  }
}
