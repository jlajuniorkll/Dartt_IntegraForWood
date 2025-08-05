import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Cadireta {
  int cadcont;
  String cadpai;
  String cadfilho;
  String cadstatus;
  String cadsuscad;
  String cadpainome;
  String cadfilnome;
  String cadpaium;
  String cadfilum;
  double caduso;
  double cadcomp;
  double cadlarg;
  double cadesp;
  double cadpeso;
  int cadfase;
  DateTime cadgrav;
  String cadhora;
  DateTime? cadimpdt;
  String cadimphr;
  String cadusuimp;
  String cadlocal;
  int cadgrpai;
  int cadsgpai;
  int cadsgrfil;
  int cadsgfil;
  int cadoriemb;
  String cadproj;
  String cadarquivo;
  double cadcobr;
  double cadlabr;
  double cadesbr;
  String cadclass;
  String cadplcor;
  String cadusamed;
  String cadborint;
  String cadbordsup;
  String cadbordinf;
  String cadboresq;
  String cadbordir;
  double cadpaiarea;
  String cadtpfil;
  int cadpembpr;
  int cadpembpp;
  String cadindter;
  double caddimper;
  String cadapp;
  Cadireta({
    required this.cadcont,
    required this.cadpai,
    required this.cadfilho,
    this.cadstatus = 'N',
    required this.cadsuscad,
    required this.cadpainome,
    required this.cadfilnome,
    required this.cadpaium,
    required this.cadfilum,
    required this.caduso,
    this.cadcomp = 0,
    this.cadlarg = 0,
    this.cadesp = 0,
    required this.cadpeso,
    required this.cadfase,
    required this.cadgrav,
    required this.cadhora,
    this.cadimpdt,
    this.cadimphr = '',
    this.cadusuimp = '',
    this.cadlocal = '',
    required this.cadgrpai,
    required this.cadsgpai,
    required this.cadsgrfil,
    required this.cadsgfil,
    required this.cadoriemb,
    required this.cadproj,
    required this.cadarquivo,
    this.cadcobr = 0,
    this.cadlabr = 0,
    this.cadesbr = 0,
    this.cadclass = '',
    required this.cadplcor,
    required this.cadusamed,
    this.cadborint = 'N',
    this.cadbordsup = 'N',
    this.cadbordinf = 'N',
    this.cadboresq = 'N',
    this.cadbordir = 'N',
    required this.cadpaiarea,
    this.cadtpfil = '',
    required this.cadpembpr,
    required this.cadpembpp,
    required this.cadindter,
    this.caddimper = 0.00,
    this.cadapp = 'PDM',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cadcont': cadcont,
      'cadpai': cadpai,
      'cadfilho': cadfilho,
      'cadstatus': cadstatus,
      'cadsuscad': cadsuscad,
      'cadpainome': cadpainome,
      'cadfilnome': cadfilnome,
      'cadpaium': cadpaium,
      'cadfilum': cadfilum,
      'caduso': caduso,
      'cadcomp': cadcomp,
      'cadlarg': cadlarg,
      'cadesp': cadesp,
      'cadpeso': cadpeso,
      'cadfase': cadfase,
      'cadgrav': cadgrav.millisecondsSinceEpoch,
      'cadhora': cadhora,
      'cadimpdt': cadimpdt?.millisecondsSinceEpoch,
      'cadimphr': cadimphr,
      'cadusuimp': cadusuimp,
      'cadlocal': cadlocal,
      'cadgrpai': cadgrpai,
      'cadsgpai': cadsgpai,
      'cadsgrfil': cadsgrfil,
      'cadsgfil': cadsgfil,
      'cadoriemb': cadoriemb,
      'cadproj': cadproj,
      'cadarquivo': cadarquivo,
      'cadcobr': cadcobr,
      'cadlabr': cadlabr,
      'cadesbr': cadesbr,
      'cadclass': cadclass,
      'cadplcor': cadplcor,
      'cadusamed': cadusamed,
      'cadborint': cadborint,
      'cadbordsup': cadbordsup,
      'cadbordinf': cadbordinf,
      'cadboresq': cadboresq,
      'cadbordir': cadbordir,
      'cadpaiarea': cadpaiarea,
      'cadtpfil': cadtpfil,
      'cadpembpr': cadpembpr,
      'cadpembpp': cadpembpp,
      'cadindter': cadindter,
      'caddimper': caddimper,
      'cadapp': cadapp,
    };
  }

  factory Cadireta.fromMap(Map<String, dynamic> map) {
    return Cadireta(
      cadcont: map['cadcont'] as int,
      cadpai: map['cadpai'] as String,
      cadfilho: map['cadfilho'] as String,
      cadstatus: map['cadstatus'] as String,
      cadsuscad: map['cadsuscad'] as String,
      cadpainome: map['cadpainome'] as String,
      cadfilnome: map['cadfilnome'] as String,
      cadpaium: map['cadpaium'] as String,
      cadfilum: map['cadfilum'] as String,
      caduso: map['caduso'] as double,
      cadcomp: map['cadcomp'] as double,
      cadlarg: map['cadlarg'] as double,
      cadesp: map['cadesp'] as double,
      cadpeso: map['cadpeso'] as double,
      cadfase: map['cadfase'] as int,
      cadgrav: DateTime.fromMillisecondsSinceEpoch(map['cadgrav'] as int),
      cadhora: map['cadhora'] as String,
      cadimpdt:
          map['cadimpdt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['cadimpdt'] as int)
              : null,
      cadimphr: map['cadimphr'] as String,
      cadusuimp: map['cadusuimp'] as String,
      cadlocal: map['cadlocal'] as String,
      cadgrpai: map['cadgrpai'] as int,
      cadsgpai: map['cadsgpai'] as int,
      cadsgrfil: map['cadsgrfil'] as int,
      cadsgfil: map['cadsgfil'] as int,
      cadoriemb: map['cadoriemb'] as int,
      cadproj: map['cadproj'] as String,
      cadarquivo: map['cadarquivo'] as String,
      cadcobr: map['cadcobr'] as double,
      cadlabr: map['cadlabr'] as double,
      cadesbr: map['cadesbr'] as double,
      cadclass: map['cadclass'] as String,
      cadplcor: map['cadplcor'] as String,
      cadusamed: map['cadusamed'] as String,
      cadborint: map['cadborint'] as String,
      cadbordsup: map['cadbordsup'] as String,
      cadbordinf: map['cadbordinf'] as String,
      cadboresq: map['cadboresq'] as String,
      cadbordir: map['cadbordir'] as String,
      cadpaiarea: map['cadpaiarea'] as double,
      cadtpfil: map['cadtpfil'] as String,
      cadpembpr: map['cadpembpr'] as int,
      cadpembpp: map['cadpembpp'] as int,
      cadindter: map['cadindter'] as String,
      caddimper: map['caddimper'] as double,
      cadapp: map['cadapp'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Cadireta.fromJson(String source) =>
      Cadireta.fromMap(json.decode(source) as Map<String, dynamic>);
}
