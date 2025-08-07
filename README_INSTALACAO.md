# DarttIntegraForwood - Guia de Instalação

## Requisitos do Sistema

- Windows 10 ou superior
- Microsoft Visual C++ Redistributable 2019 ou superior
- Drivers ODBC para SQL Server
- Drivers ODBC para PostgreSQL (se necessário)
- Diretórios de trabalho configurados (XML, Industrial)

## Instalação

### 1. Preparação do Ambiente

#### 1.1 Microsoft Visual C++ Redistributable

Verifique se o Microsoft Visual C++ Redistributable 2019 ou superior está instalado no sistema. Caso não esteja, faça o download e instale a partir do site oficial da Microsoft:

- [Microsoft Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

#### 1.2 Drivers ODBC

##### SQL Server

Para conexões com SQL Server, instale o driver ODBC mais recente:

1. Faça o download do [ODBC Driver for SQL Server](https://go.microsoft.com/fwlink/?linkid=2249006)
2. Execute o instalador e siga as instruções

##### PostgreSQL (se necessário)

Para conexões com PostgreSQL, instale o driver ODBC:

1. Faça o download do [PostgreSQL ODBC Driver](https://www.postgresql.org/ftp/odbc/versions/)
2. Execute o instalador e siga as instruções

### 2. Instalação do Aplicativo

1. Extraia o arquivo ZIP do aplicativo para uma pasta de sua escolha
2. Execute o arquivo `start_app.bat` para verificar as dependências e iniciar o aplicativo
3. Alternativamente, execute diretamente o arquivo `dartt_integraforwood.exe`

### 3. Configuração Inicial

Na primeira execução do aplicativo, acesse as configurações para definir:

#### 3.1 Conexões com Bancos de Dados

- **SQL Server**:
  - Host/IP
  - Porta
  - Nome do banco de dados
  - Nome de usuário
  - Senha

- **PostgreSQL** (ForWood):
  - Host/IP
  - Porta
  - Nome do banco de dados
  - Nome de usuário
  - Senha

#### 3.2 Diretórios de Trabalho

- **Diretório XML**: Caminho para os arquivos XML (ex: `T:\xml`)
- **Diretório ESP**: Caminho para os executáveis ESP (ex: `C:\Industrial`)

#### 3.3 Códigos de Batismo

- Código de batismo para módulo
- Código de batismo para corte
- Código de batismo para pedido

#### 3.4 Unidades de Medida

- Código UMM2
- Código UMM3

## Solução de Problemas

### Problemas de Conexão com Banco de Dados

1. Verifique se os drivers ODBC estão instalados corretamente
2. Confirme se as credenciais de acesso estão corretas
3. Verifique se o servidor de banco de dados está acessível na rede

### Problemas com Executáveis ESP

1. Verifique se o diretório ESP está configurado corretamente
2. Confirme se os executáveis ESP0019.exe e ES05072.exe existem no diretório
3. Verifique as permissões de acesso aos arquivos

### Problemas com Arquivos XML

1. Verifique se o diretório XML está configurado corretamente
2. Confirme se o aplicativo tem permissões para ler/escrever no diretório

## Distribuição

Para distribuir o aplicativo para outros usuários:

1. Execute o script `package_windows_app.ps1` para criar um pacote de distribuição
2. Distribua o arquivo ZIP gerado
3. Forneça este guia de instalação junto com o pacote

## Suporte

Para suporte técnico, entre em contato com o desenvolvedor do aplicativo.