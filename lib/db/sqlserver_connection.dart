import 'dart:ffi';
import 'dart:convert';
import 'package:ffi/ffi.dart';

class SqlServerConnection {
  static SqlServerConnection? _instance;
  int _hEnv = 0;
  int _hDbc = 0;
  bool _isConnected = false;

  SqlServerConnection._internal();

  static SqlServerConnection getInstance() {
    _instance ??= SqlServerConnection._internal();
    return _instance!;
  }

  // Getter para compatibilidade com código existente
  SqlServerConnection get mssqlConnection => this;

  Future<bool> connect({
    required String ip,
    required String port,
    required String database,
    required String username,
    required String password,
  }) async {
    return await connectWithProgress(
      ip: ip,
      port: port,
      database: database,
      username: username,
      password: password,
    );
  }

  Future<bool> connectWithProgress({
    required String ip,
    required String port,
    required String database,
    required String username,
    required String password,
    Function(int attempt, int total, String driver)? onProgress,
  }) async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      // Inicializar ODBC Environment
      _hEnv = _allocateEnvironment();
      if (_hEnv == 0) return false;

      // Alocar Connection Handle
      _hDbc = _allocateConnection(_hEnv);
      if (_hDbc == 0) return false;

      // Montar string de conexão com diferentes drivers e formatos
      List<Map<String, String>> connectionConfigs = [
        {
          'name': 'ODBC Driver 17',
          'connectionString': 'DRIVER={ODBC Driver 17 for SQL Server};'
              'SERVER=$ip;'
              'DATABASE=$database;'
              'UID=$username;'
              'PWD=$password;'
              'TrustServerCertificate=yes;'
              'Encrypt=no;',
        },
        {
          'name': 'ODBC Driver 13',
          'connectionString': 'DRIVER={ODBC Driver 13 for SQL Server};'
              'SERVER=$ip;'
              'DATABASE=$database;'
              'UID=$username;'
              'PWD=$password;'
              'TrustServerCertificate=yes;'
              'Encrypt=no;',
        },
        {
          'name': 'SQL Server Native Client 11.0',
          'connectionString': 'DRIVER={SQL Server Native Client 11.0};'
              'SERVER=$ip;'
              'DATABASE=$database;'
              'UID=$username;'
              'PWD=$password;'
              'TrustServerCertificate=yes;'
              'Encrypt=no;',
        },
        {
          'name': 'SQL Server (padrão)',
          'connectionString': 'DRIVER={SQL Server};'
              'SERVER=$ip;'
              'DATABASE=$database;'
              'UID=$username;'
              'PWD=$password;',
        },
        {
          'name': 'SQLOLEDB.1',
          'connectionString': 'Provider=SQLOLEDB.1;'
              'Data Source=$ip;'
              'Initial Catalog=$database;'
              'User ID=$username;'
              'Password=$password;'
              'TrustServerCertificate=Yes;'
              'Encrypt=No;',
        },
      ];
      
      // Tentar cada string de conexão
      for (int i = 0; i < connectionConfigs.length; i++) {
        final config = connectionConfigs[i];
        final driverName = config['name']!;
        final connectionString = config['connectionString']!;
        
        // Notificar progresso
        onProgress?.call(i + 1, connectionConfigs.length, driverName);
        
        print('Tentativa ${i + 1} de ${connectionConfigs.length}: $driverName');
        print('String de conexão: ${connectionString.replaceAll(password, '***')}');
        
        bool connected = _connectWithString(connectionString);
        if (connected) {
          _isConnected = connected;
          print('Conexão bem-sucedida na tentativa ${i + 1} com $driverName');
          return connected;
        }
        print('Tentativa ${i + 1} com $driverName falhou, tentando próxima...');
      }

      // Se chegou aqui, todas as tentativas falharam
      _isConnected = false;
      print('Todas as ${connectionConfigs.length} tentativas de conexão falharam');
      return false;
    } catch (e) {
      print('Erro na conexão SQL Server: $e');
      return false;
    }
  }

  Future<String> getData(String query) async {
    if (!_isConnected) {
      return jsonEncode([
        {'erro': 'Não conectado ao banco de dados'},
      ]);
    }

    try {
      List<Map<String, dynamic>> results = _executeQuery(query);
      return jsonEncode(results);
    } catch (e) {
      print('Erro ao executar query: $e');
      return jsonEncode([
        {'erro': 'Erro ao executar consulta: $e'},
      ]);
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      _disconnectDatabase();
      _isConnected = false;
    }

    if (_hDbc != 0) {
      _freeConnection(_hDbc);
      _hDbc = 0;
    }

    if (_hEnv != 0) {
      _freeEnvironment(_hEnv);
      _hEnv = 0;
    }
  }

  Future<void> close() async {
    await disconnect();
  }

  // Métodos nativos usando Win32 API
  int _allocateEnvironment() {
    try {
      final pEnv = calloc<IntPtr>();
      final result = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, pEnv);

      if (result == SQL_SUCCESS || result == SQL_SUCCESS_WITH_INFO) {
        final hEnv = pEnv.value;
        SQLSetEnvAttr(hEnv, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, 0);
        calloc.free(pEnv);
        return hEnv;
      }

      calloc.free(pEnv);
      return 0;
    } catch (e) {
      print('Erro ao alocar environment: $e');
      return 0;
    }
  }

  int _allocateConnection(int hEnv) {
    try {
      final pDbc = calloc<IntPtr>();
      final result = SQLAllocHandle(SQL_HANDLE_DBC, hEnv, pDbc);

      if (result == SQL_SUCCESS || result == SQL_SUCCESS_WITH_INFO) {
        final hDbc = pDbc.value;
        calloc.free(pDbc);
        return hDbc;
      }

      calloc.free(pDbc);
      return 0;
    } catch (e) {
      print('Erro ao alocar conexão: $e');
      return 0;
    }
  }

  bool _connectWithString(String connectionString) {
    try {
      final connStr = connectionString.toNativeUtf16().cast<Uint16>();
      final outConnStr = calloc<Uint16>(1024);
      final outConnStrLen = calloc<Int16>();

      final result = SQLDriverConnect(
        _hDbc,
        0, // No window handle
        connStr,
        connectionString.length,
        outConnStr,
        1024,
        outConnStrLen,
        SQL_DRIVER_NOPROMPT,
      );

      calloc.free(connStr);
      calloc.free(outConnStr);
      calloc.free(outConnStrLen);

      if (result == SQL_SUCCESS || result == SQL_SUCCESS_WITH_INFO) {
        print('Conexão SQLOLEDB estabelecida com sucesso');
        return true;
      } else {
        print('Falha na conexão SQLOLEDB. Código de erro: $result');
        _printSQLError();
        return false;
      }
    } catch (e) {
      print('Erro ao conectar com string: $e');
      return false;
    }
  }

  void _printSQLError() {
    try {
      final sqlState = calloc<Uint16>(6);
      final nativeError = calloc<Int32>();
      final messageText = calloc<Uint16>(1024);
      final textLength = calloc<Int16>();

      // Tentar obter informações de erro
      print('Detalhes do erro de conexão SQLOLEDB:');
      print('- Verifique se o SQL Server está rodando');
      print('- Verifique se o serviço SQL Server Browser está ativo');
      print('- Confirme o nome da instância: NOTEDARTT\\ECADPRO2019');
      print('- Verifique as credenciais: sa / eCadPro2019');
      print('- Verifique configurações de firewall');

      calloc.free(sqlState);
      calloc.free(nativeError);
      calloc.free(messageText);
      calloc.free(textLength);
    } catch (e) {
      print('Erro ao obter detalhes do erro: $e');
    }
  }

  List<Map<String, dynamic>> _executeQuery(String query) {
    try {
      final pStmt = calloc<IntPtr>();
      final result = SQLAllocHandle(SQL_HANDLE_STMT, _hDbc, pStmt);

      if (result != SQL_SUCCESS && result != SQL_SUCCESS_WITH_INFO) {
        calloc.free(pStmt);
        throw Exception('Erro ao alocar statement');
      }

      final hStmt = pStmt.value;
      calloc.free(pStmt);

      // Executar query
      final queryStr = query.toNativeUtf16().cast<Uint16>();
      final execResult = SQLExecDirect(hStmt, queryStr, query.length);
      calloc.free(queryStr);

      if (execResult != SQL_SUCCESS && execResult != SQL_SUCCESS_WITH_INFO) {
        SQLFreeHandle(SQL_HANDLE_STMT, hStmt);
        throw Exception('Erro ao executar query');
      }

      // Obter resultados
      List<Map<String, dynamic>> results = _fetchResults(hStmt);

      SQLFreeHandle(SQL_HANDLE_STMT, hStmt);
      return results;
    } catch (e) {
      print('Erro ao executar query: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _fetchResults(int hStmt) {
    List<Map<String, dynamic>> results = [];

    try {
      // Obter número de colunas
      final pNumCols = calloc<Int16>();
      SQLNumResultCols(hStmt, pNumCols);
      final numCols = pNumCols.value;
      calloc.free(pNumCols);

      if (numCols <= 0) return results;

      // Obter nomes das colunas
      List<String> columnNames = [];
      for (int i = 1; i <= numCols; i++) {
        final colName = calloc<Uint16>(256);
        final nameLen = calloc<Int16>();

        SQLColAttribute(
          hStmt,
          i,
          SQL_DESC_NAME,
          colName,
          256,
          nameLen,
          nullptr,
        );
        columnNames.add(colName.cast<Utf16>().toDartString());

        calloc.free(colName);
        calloc.free(nameLen);
      }

      // Fetch rows
      while (SQLFetch(hStmt) == SQL_SUCCESS) {
        Map<String, dynamic> row = {};

        for (int i = 1; i <= numCols; i++) {
          final data = calloc<Uint16>(1024);
          final indicator = calloc<IntPtr>();

          final result = SQLGetData(
            hStmt,
            i,
            SQL_C_WCHAR,
            data,
            1024,
            indicator,
          );

          if (result == SQL_SUCCESS || result == SQL_SUCCESS_WITH_INFO) {
            if (indicator.value != SQL_NULL_DATA) {
              row[columnNames[i - 1]] = data.cast<Utf16>().toDartString();
            } else {
              row[columnNames[i - 1]] = null;
            }
          }

          calloc.free(data);
          calloc.free(indicator);
        }

        results.add(row);
      }

      return results;
    } catch (e) {
      print('Erro ao buscar resultados: $e');
      return results;
    }
  }

  void _disconnectDatabase() {
    if (_hDbc != 0) {
      SQLDisconnect(_hDbc);
    }
  }

  void _freeConnection(int hDbc) {
    SQLFreeHandle(SQL_HANDLE_DBC, hDbc);
  }

  void _freeEnvironment(int hEnv) {
    SQLFreeHandle(SQL_HANDLE_ENV, hEnv);
  }

  // Constantes ODBC
  static const int SQL_HANDLE_ENV = 1;
  static const int SQL_HANDLE_DBC = 2;
  static const int SQL_HANDLE_STMT = 3;
  static const int SQL_NULL_HANDLE = 0;
  static const int SQL_SUCCESS = 0;
  static const int SQL_SUCCESS_WITH_INFO = 1;
  static const int SQL_ATTR_ODBC_VERSION = 200;
  static const int SQL_OV_ODBC3 = 3;
  static const int SQL_DRIVER_NOPROMPT = 0;
  static const int SQL_C_WCHAR = -8;
  static const int SQL_DESC_NAME = 1011;
  static const int SQL_NULL_DATA = -1;
}

// Funções ODBC via Win32
final _odbc32 = DynamicLibrary.open('odbc32.dll');

final SQLAllocHandle = _odbc32.lookupFunction<
  Int32 Function(Int16, IntPtr, Pointer<IntPtr>),
  int Function(int, int, Pointer<IntPtr>)
>('SQLAllocHandle');

final SQLSetEnvAttr = _odbc32.lookupFunction<
  Int32 Function(IntPtr, Int32, IntPtr, Int32),
  int Function(int, int, int, int)
>('SQLSetEnvAttr');

final SQLDriverConnect = _odbc32.lookupFunction<
  Int32 Function(
    IntPtr,
    IntPtr,
    Pointer<Uint16>,
    Int16,
    Pointer<Uint16>,
    Int16,
    Pointer<Int16>,
    Int16,
  ),
  int Function(
    int,
    int,
    Pointer<Uint16>,
    int,
    Pointer<Uint16>,
    int,
    Pointer<Int16>,
    int,
  )
>('SQLDriverConnectW');

final SQLExecDirect = _odbc32.lookupFunction<
  Int32 Function(IntPtr, Pointer<Uint16>, Int32),
  int Function(int, Pointer<Uint16>, int)
>('SQLExecDirectW');

final SQLNumResultCols = _odbc32.lookupFunction<
  Int32 Function(IntPtr, Pointer<Int16>),
  int Function(int, Pointer<Int16>)
>('SQLNumResultCols');

final SQLColAttribute = _odbc32.lookupFunction<
  Int32 Function(
    IntPtr,
    Int16,
    Int16,
    Pointer<Uint16>,
    Int16,
    Pointer<Int16>,
    Pointer<IntPtr>,
  ),
  int Function(
    int,
    int,
    int,
    Pointer<Uint16>,
    int,
    Pointer<Int16>,
    Pointer<IntPtr>,
  )
>('SQLColAttributeW');

final SQLFetch = _odbc32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('SQLFetch');

final SQLGetData = _odbc32.lookupFunction<
  Int32 Function(
    IntPtr,
    Int16,
    Int16,
    Pointer<Uint16>,
    IntPtr,
    Pointer<IntPtr>,
  ),
  int Function(int, int, int, Pointer<Uint16>, int, Pointer<IntPtr>)
>('SQLGetData');

final SQLDisconnect = _odbc32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('SQLDisconnect');

final SQLFreeHandle = _odbc32
    .lookupFunction<Int32 Function(Int16, IntPtr), int Function(int, int)>(
      'SQLFreeHandle',
    );
