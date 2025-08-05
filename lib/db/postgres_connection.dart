import 'package:postgres/postgres.dart';

class PostgresConnection {
  static final PostgresConnection _instance = PostgresConnection._internal();
  factory PostgresConnection() => _instance;
  PostgresConnection._internal();

  Connection? connection;

  Future<bool> connect({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    try {
      connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> close() async {
    await connection!.close();
  }
}
