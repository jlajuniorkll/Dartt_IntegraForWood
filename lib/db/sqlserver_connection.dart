import 'package:mssql_connection/mssql_connection.dart';

class SqlServerConnection {
  MssqlConnection mssqlConnection = MssqlConnection.getInstance();
  Future<bool> connect({
    required String ip,
    required String port,
    required String database,
    required String username,
    required String password,
  }) async {
    try {
      await mssqlConnection.connect(
        ip: ip,
        port: port,
        databaseName: database,
        username: username,
        password: password,
        timeoutInSeconds: 15,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> close() async {
    await mssqlConnection.disconnect();
  }
}
