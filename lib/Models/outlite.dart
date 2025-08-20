import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Outlite {
  String? data;
  String? numero;
  String? numeroFabricacao; // Novo campo para armazenar o número de fabricação
  String? dataDesenho;
  String rif = "";
  String fileName = "";
  List<ItemBox>? itembox;
  String codpai = "";
  
  Outlite({
    this.data,
    this.numero,
    this.numeroFabricacao, // Adicionar ao construtor
    this.dataDesenho,
    required this.rif,
    required this.fileName,
    this.itembox,
    this.codpai = "",
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'data': data,
      'numero': numero,
      'numeroFabricacao': numeroFabricacao, // Adicionar ao mapa
      'dataDesenho': dataDesenho,
      'rif': rif,
      'fileName': fileName,
      'itembox': itembox?.map((x) => x.toMap()).toList(),
      'codpai': codpai,
    };
  }

  factory Outlite.fromMap(Map<String, dynamic> map) {
    return Outlite(
      data: map['data'] != null ? map['data'] as String : null,
      numero: map['numero'] != null ? map['numero'] as String : null,
      numeroFabricacao: map['numeroFabricacao'] != null ? map['numeroFabricacao'] as String : null, // Adicionar ao fromMap
      dataDesenho: map['dataDesenho'] != null ? map['dataDesenho'] as String : null,
      rif: map['rif'] as String,
      fileName: map['fileName'] as String,
      codpai: map['codpai'] != null ? map['codpai'] as String : "",
      itembox:
          map['itembox'] != null
              ? List<ItemBox>.from(
                (map['itembox'] as List<int>).map<ItemBox?>(
                  (x) => ItemBox.fromMap(x as Map<String, dynamic>),
                ),
              )
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Outlite.fromJson(String source) =>
      Outlite.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ItemBox {
  int? riga;
  String? codigo;
  String? des;
  String? pz;
  String? qta;
  String? l;
  String? a;
  String? p;
  List<ItemPecas>? itemPecas;
  List<ItemPrice>? itemPrice;
  ItemBox({
    this.riga,
    this.codigo,
    this.des,
    this.pz,
    this.qta,
    this.l,
    this.a,
    this.p,
    this.itemPecas,
    this.itemPrice,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'riga': riga,
      'codigo': codigo,
      'des': des,
      'pz': pz,
      'qta': qta,
      'l': l,
      'a': a,
      'p': p,
      'itemPecas': itemPecas!.map((x) => x.toMap()).toList(),
      'itemPrice': itemPrice!.map((x) => x.toMap()).toList(),
    };
  }

  factory ItemBox.fromMap(Map<String, dynamic> map) {
    return ItemBox(
      riga: map['riga'] != null ? map['riga'] as int : null,
      codigo: map['codigo'] != null ? map['codigo'] as String : null,
      des: map['des'] != null ? map['des'] as String : null,
      pz: map['pz'] != null ? map['pz'] as String : null,
      qta: map['qta'] != null ? map['qta'] as String : null,
      l: map['l'] != null ? map['l'] as String : null,
      a: map['a'] != null ? map['a'] as String : null,
      p: map['p'] != null ? map['p'] as String : null,
      itemPecas:
          map['itemPecas'] != null
              ? List<ItemPecas>.from(
                (map['itemPecas'] as List<int>).map<ItemPecas?>(
                  (x) => ItemPecas.fromMap(x as Map<String, dynamic>),
                ),
              )
              : null,
      itemPrice:
          map['itemPrice'] != null
              ? List<ItemPrice>.from(
                (map['itemPrice'] as List<int>).map<ItemPrice?>(
                  (x) => ItemPrice.fromMap(x as Map<String, dynamic>),
                ),
              )
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemBox.fromJson(String source) =>
      ItemBox.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ItemPecas {
  String? codpeca;
  String? idpeca;
  String? comprimento;
  String? largura;
  String? espessura;
  String? codcor;
  String? codpainel;
  String? codborda;
  String? trabalhoesq;
  String? trabalhodir;
  String? trabalhofre;
  String? trabalhotra;
  String? fitaesq;
  String? fitadir;
  String? fitafre;
  String? fitatra;
  String? cava;
  String? nbox;
  String? qta;
  String? codbordafrente;
  String? variaveis;
  String? grupo;
  String? subgrupo;
  String? um;
  String? origem;
  String? status;
  String? fase;
  String? matricula; // Novo campo para armazenar a matrícula
  
  ItemPecas({
    this.codpeca,
    this.idpeca,
    this.comprimento,
    this.largura,
    this.espessura,
    this.codcor,
    this.codpainel,
    this.codborda,
    // Remover estas linhas:
    // this.nomePRG1 = '',
    // this.nomePRG2 = '',
    this.trabalhoesq,
    this.trabalhodir,
    this.trabalhofre,
    this.trabalhotra,
    this.fitaesq,
    this.fitadir,
    this.fitafre,
    this.fitatra,
    this.cava,
    this.nbox,
    this.qta,
    this.codbordafrente,
    this.variaveis,
    this.grupo,
    this.subgrupo,
    this.um,
    this.origem,
    this.status,
    this.fase,
    this.matricula, // Adicionar ao construtor
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'codpeca': codpeca,
      'idpeca': idpeca,
      'comprimento': comprimento,
      'largura': largura,
      'espessura': espessura,
      'codcor': codcor,
      'codpainel': codpainel,
      'codborda': codborda,
      // Remover estas linhas:
      // 'nomePRG1': nomePRG1,
      // 'nomePRG2': nomePRG2,
      'trabalhoesq': trabalhoesq,
      'trabalhodir': trabalhodir,
      'trabalhofre': trabalhofre,
      'trabalhotra': trabalhotra,
      'fitaesq': fitaesq,
      'fitadir': fitadir,
      'fitafre': fitafre,
      'fitatra': fitatra,
      'cava': cava,
      'nbox': nbox,
      'qta': qta,
      'codbordafrente': codbordafrente,
      'variaveis': variaveis,
      'grupo': grupo,
      'subgrupo': subgrupo,
      'um': um,
      'origem': origem,
      'status': status,
      'fase': fase,
      'matricula': matricula, // Adicionar ao mapa
    };
  }

  factory ItemPecas.fromMap(Map<String, dynamic> map) {
    return ItemPecas(
      codpeca: map['codpeca'] != null ? map['codpeca'] as String : null,
      idpeca: map['idpeca'] != null ? map['idpeca'] as String : null,
      comprimento: map['comprimento'] != null ? map['comprimento'] as String : null,
      largura: map['largura'] != null ? map['largura'] as String : null,
      espessura: map['espessura'] != null ? map['espessura'] as String : null,
      codcor: map['codcor'] != null ? map['codcor'] as String : null,
      codpainel: map['codpainel'] != null ? map['codpainel'] as String : null,
      codborda: map['codborda'] != null ? map['codborda'] as String : null,
      // Remover estas linhas:
      // nomePRG1: map['nomePRG1'] as String,
      // nomePRG2: map['nomePRG2'] as String,
      trabalhoesq: map['trabalhoesq'] != null ? map['trabalhoesq'] as String : null,
      trabalhodir: map['trabalhodir'] != null ? map['trabalhodir'] as String : null,
      trabalhofre: map['trabalhofre'] != null ? map['trabalhofre'] as String : null,
      trabalhotra: map['trabalhotra'] != null ? map['trabalhotra'] as String : null,
      fitaesq: map['fitaesq'] != null ? map['fitaesq'] as String : null,
      fitadir: map['fitadir'] != null ? map['fitadir'] as String : null,
      fitafre: map['fitafre'] != null ? map['fitafre'] as String : null,
      fitatra: map['fitatra'] != null ? map['fitatra'] as String : null,
      cava: map['cava'] != null ? map['cava'] as String : null,
      nbox: map['nbox'] != null ? map['nbox'] as String : null,
      qta: map['qta'] != null ? map['qta'] as String : null,
      codbordafrente: map['codbordafrente'] != null ? map['codbordafrente'] as String : null,
      variaveis: map['variaveis'] != null ? map['variaveis'] as String : null,
      grupo: map['grupo'] != null ? map['grupo'] as String : null,
      subgrupo: map['subgrupo'] != null ? map['subgrupo'] as String : null,
      um: map['um'] != null ? map['um'] as String : null,
      origem: map['origem'] != null ? map['origem'] as String : null,
      status: map['status'] != null ? map['status'] as String : null,
      fase: map['fase'] != null ? map['fase'] as String : null,
      matricula: map['matricula'] != null ? map['matricula'] as String : null, // Adicionar ao fromMap
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemPecas.fromJson(String source) =>
      ItemPecas.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ItemPrice {
  int? riga;
  String? codigo;
  String? des;
  String? qtd;
  String? grupo;
  String? subgrupo;
  String? um;
  String? origem;
  String? status;
  String? fase;
  String? matricula; // Novo campo para armazenar a matrícula
  
  ItemPrice({
    this.riga, 
    this.codigo, 
    this.des, 
    this.qtd,
    this.matricula, // Adicionar ao construtor
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'riga': riga,
      'codigo': codigo,
      'des': des,
      'qtd': qtd,
      'matricula': matricula, // Adicionar ao mapa
    };
  }

  factory ItemPrice.fromMap(Map<String, dynamic> map) {
    return ItemPrice(
      riga: map['riga'] != null ? map['riga'] as int : null,
      codigo: map['codigo'] != null ? map['codigo'] as String : null,
      des: map['des'] != null ? map['des'] as String : null,
      qtd: map['qtd'] != null ? map['qtd'] as String : null,
      matricula: map['matricula'] != null ? map['matricula'] as String : null, // Adicionar ao fromMap
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemPrice.fromJson(String source) =>
      ItemPrice.fromMap(json.decode(source) as Map<String, dynamic>);
}
