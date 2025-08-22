import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../Models/xml_history.dart';

class XmlImportadoService {
  static Database? _database;
  static const String _databaseName = 'xmls_importados.db';
  static const String _tableName = 'xmls_importados';

  // Singleton pattern
  static final XmlImportadoService _instance = XmlImportadoService._internal();
  factory XmlImportadoService() => _instance;
  XmlImportadoService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // ignore: avoid_print
    print('Caminho do banco SQLite: $path'); // Debug

    Database db = await openDatabase(
      path,
      version: 3, // Incrementando versão para nova migração
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    // Corrigir dados incorretos após abrir o banco - passando o db diretamente
    await _fixIncorrectStatusData(db);

    return db;
  }

  // Método para corrigir dados de status incorretos
  Future<void> _fixIncorrectStatusData(Database db) async {
    try {
      // Corrigir status vazios ou nulos para 'aguardando'
      await db.update(_tableName, {
        'status': 'aguardando',
      }, where: 'status IS NULL OR status = ""');

      // Corrigir revisões nulas ou zero para 1
      await db.update(_tableName, {
        'revisao': 1,
      }, where: 'revisao IS NULL OR revisao = 0');
      // ignore: avoid_print
      print('Dados de status corrigidos com sucesso');
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao corrigir dados de status: $e');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL,
        rif TEXT NOT NULL,
        pai TEXT NOT NULL,
        data TEXT NOT NULL,
        numeroFabricacao TEXT,
        status TEXT NOT NULL DEFAULT 'aguardando',
        jsonCadiredi TEXT,
        jsonCadireta TEXT,
        jsonCadproce TEXT,
        jsonOutlite TEXT,
        jsonCadire2 TEXT,
        revisao INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER
      )
    ''');

    // Criar índices para melhor performance
    await db.execute('CREATE INDEX idx_numero ON $_tableName (numero)');
    await db.execute('CREATE INDEX idx_status ON $_tableName (status)');
    await db.execute('CREATE INDEX idx_created_at ON $_tableName (createdAt)');
    await db.execute('CREATE INDEX idx_revisao ON $_tableName (revisao)');
  }

  // Método para migração do banco de dados
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Adicionar campo revisao para versão 2
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN revisao INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute('CREATE INDEX idx_revisao ON $_tableName (revisao)');
    }
    if (oldVersion < 3) {
      // Adicionar campo jsonOutlite para versão 3
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN jsonOutlite TEXT',
      );
    }
  }

  // Inserir novo XML importado
  Future<int> insertXmlImportado(XmlImportado xmlImportado) async {
    final db = await database;
    return await db.insert(_tableName, xmlImportado.toMap());
  }

  // Buscar todos os XMLs importados (apenas a revisão mais recente de cada)
  Future<List<XmlImportado>> getAllXmlsImportados() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $_tableName t1
      WHERE t1.revisao = (
        SELECT MAX(t2.revisao) 
        FROM $_tableName t2 
        WHERE t2.numero = t1.numero
      )
      ORDER BY t1.createdAt DESC
    ''');

    return List.generate(maps.length, (i) {
      return XmlImportado.fromMap(maps[i]);
    });
  }

  // Buscar XMLs por status (apenas a revisão mais recente de cada)
  Future<List<XmlImportado>> getXmlsByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM $_tableName t1
      WHERE t1.status = ? AND t1.revisao = (
        SELECT MAX(t2.revisao) 
        FROM $_tableName t2 
        WHERE t2.numero = t1.numero
      )
      ORDER BY t1.createdAt DESC
    ''',
      [status],
    );

    return List.generate(maps.length, (i) {
      return XmlImportado.fromMap(maps[i]);
    });
  }

  // Buscar XML por ID
  Future<XmlImportado?> getXmlImportadoById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return XmlImportado.fromMap(maps.first);
    }
    return null;
  }

  // Atualizar XML importado
  Future<int> updateXmlImportado(XmlImportado xmlImportado) async {
    final db = await database;
    return await db.update(
      _tableName,
      xmlImportado.toMap(),
      where: 'id = ?',
      whereArgs: [xmlImportado.id],
    );
  }

  // Verificar se um XML pode receber novas revisões
  Future<bool> canCreateNewRevision(String numero) async {
    final latestRevision = await getLatestRevisionByNumero(numero);
    if (latestRevision == null) return true;

    // Não permitir novas revisões se estiver em produção ou finalizado
    return latestRevision.status != 'em_producao' &&
        latestRevision.status != 'finalizado';
  }

  // Inserir ou atualizar XML importado
  Future<int> insertOrUpdateXmlImportado(
    XmlImportado xmlImportado, {
    bool forceUpdate = false,
  }) async {
    // Se tem ID, é uma atualização
    if (xmlImportado.id != null) {
      return await updateXmlImportado(xmlImportado);
    }

    // Se não tem ID, verificar se já existe um XML com o mesmo número
    bool exists = await xmlExists(xmlImportado.numero);

    if (exists) {
      // Verificar se pode criar nova revisão
      bool canCreate = await canCreateNewRevision(xmlImportado.numero);
      // Verificar se pode criar nova revisão
      if (!canCreate) {
        throw Exception(
          'Não é possível criar nova revisão. O XML está em produção ou finalizado.',
        );
      }

      if (forceUpdate) {
        // Se forceUpdate é true, atualizar o registro existente
        final existingXml = await getLatestRevisionByNumero(
          xmlImportado.numero,
        );
        if (existingXml != null) {
          xmlImportado = xmlImportado.copyWith(id: existingXml.id);
          return await updateXmlImportado(xmlImportado);
        }
      }
      // Se existe e não é forceUpdate, criar nova revisão
      return await createNewRevision(xmlImportado);
    } else {
      // Se não existe, inserir novo
      return await insertXmlImportado(xmlImportado);
    }
  }

  // Atualizar apenas o status
  Future<int> updateStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      _tableName,
      {'status': status, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Atualizar número de fabricação
  Future<int> updateNumeroFabricacao(int id, String numeroFabricacao) async {
    final db = await database;
    return await db.update(
      _tableName,
      {
        'numeroFabricacao': numeroFabricacao,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Atualizar JSONs das tabelas
  Future<int> updateJsons(
    int id, {
    String? jsonCadiredi,
    String? jsonCadireta,
    String? jsonCadproce,
    String? jsonCadire2,
  }) async {
    final db = await database;
    Map<String, dynamic> updates = {
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    if (jsonCadiredi != null) updates['jsonCadiredi'] = jsonCadiredi;
    if (jsonCadireta != null) updates['jsonCadireta'] = jsonCadireta;
    if (jsonCadproce != null) updates['jsonCadproce'] = jsonCadproce;
    if (jsonCadire2 != null) updates['jsonCadire2'] = jsonCadire2;

    return await db.update(
      _tableName,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Deletar XML importado
  Future<int> deleteXmlImportado(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Deletar todas as revisões de um XML por número
  Future<int> deleteAllRevisionsByNumero(String numero) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'numero = ?',
      whereArgs: [numero],
    );
  }

  // Buscar XMLs por conteúdo (numero, rif, pai)
  Future<List<XmlImportado>> searchXmls(
    String query, {
    String? status,
    String orderBy = 'createdAt DESC',
  }) async {
    final db = await database;

    String whereClause = '(numero LIKE ? OR rif LIKE ? OR pai LIKE ?)';
    List<String> whereArgs = ['%$query%', '%$query%', '%$query%'];

    if (status != null && status != 'todos') {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) {
      return XmlImportado.fromMap(maps[i]);
    });
  }

  // Buscar XMLs por número (todas as revisões)
  Future<List<XmlImportado>> getXmlsByNumero(String numero) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'numero = ?',
      whereArgs: [numero],
      orderBy: 'revisao DESC',
    );

    return List.generate(maps.length, (i) {
      return XmlImportado.fromMap(maps[i]);
    });
  }

  // Buscar última revisão de um XML
  Future<XmlImportado?> getLatestRevisionByNumero(String numero) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'numero = ?',
      whereArgs: [numero],
      orderBy: 'revisao DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return XmlImportado.fromMap(maps.first);
    }
    return null;
  }

  // Buscar próximo número de revisão para um XML
  Future<int> getNextRevisionNumber(String numero) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT MAX(revisao) as maxRevisao FROM $_tableName WHERE numero = ?',
      [numero],
    );

    int maxRevisao = result.first['maxRevisao'] ?? 0;
    return maxRevisao + 1;
  }

  // Verificar se existe XML com o mesmo número
  Future<bool> xmlExists(String numero) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'numero = ?',
      whereArgs: [numero],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Criar nova revisão de um XML existente
  Future<int> createNewRevision(XmlImportado xmlImportado) async {
    // Buscar próximo número de revisão
    int nextRevision = await getNextRevisionNumber(xmlImportado.numero);

    // Criar nova instância com revisão incrementada
    XmlImportado newRevision = XmlImportado(
      numero: xmlImportado.numero,
      rif: xmlImportado.rif,
      pai: xmlImportado.pai,
      data: xmlImportado.data,
      numeroFabricacao: xmlImportado.numeroFabricacao,
      status: 'aguardando', // Status inicial correto para nova revisão
      jsonCadiredi: xmlImportado.jsonCadiredi,
      jsonCadireta: xmlImportado.jsonCadireta,
      jsonCadproce: xmlImportado.jsonCadproce,
      revisao: nextRevision,
      createdAt: DateTime.now(), // Adicionar timestamp atual
    );

    return await insertXmlImportado(newRevision);
  }

  // Buscar contagem de XMLs por status
  Future<Map<String, int>> getStatusCount() async {
    final db = await database;

    // Query para contar apenas a última revisão de cada XML por status
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM $_tableName t1
      WHERE t1.revisao = (
        SELECT MAX(t2.revisao) 
        FROM $_tableName t2 
        WHERE t2.numero = t1.numero
      )
      GROUP BY status
      ''');

    // Converter resultado para Map
    Map<String, int> statusCount = {};

    // Inicializar todos os status com 0
    statusCount['aguardando'] = 0;
    statusCount['orcado'] = 0;
    statusCount['produzir'] = 0;
    statusCount['em_producao'] = 0;
    statusCount['finalizado'] = 0;

    // Preencher com os valores reais do banco
    for (var row in result) {
      String status = row['status'] ?? '';
      int count = row['count'] ?? 0;
      statusCount[status] = count;
    }

    return statusCount;
  }
}
