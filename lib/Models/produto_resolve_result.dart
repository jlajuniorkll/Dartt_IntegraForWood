// ignore_for_file: public_member_api_docs

/// Resultado da resolução SQL Server / PostgreSQL para exibição e cadireta.
class ProdutoResolveResult {
  final String idpeca;
  final String? codigoProdutoPostgres;
  final bool precisaCadastroForWood;
  final String? descricaoSqlServer;

  const ProdutoResolveResult({
    required this.idpeca,
    this.codigoProdutoPostgres,
    this.precisaCadastroForWood = false,
    this.descricaoSqlServer,
  });

  bool get isErro => idpeca.startsWith('Erro:');
}
