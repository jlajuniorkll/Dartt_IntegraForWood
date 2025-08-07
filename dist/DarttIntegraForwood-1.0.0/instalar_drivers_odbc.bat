@echo off
echo ===================================================
echo Instalador de Drivers ODBC para DarttIntegraForwood
echo ===================================================
echo.

echo Este script vai ajudar a instalar os drivers ODBC necessarios
echo para o funcionamento do aplicativo DarttIntegraForwood.
echo.

echo ATENCAO: E necessario executar este script como administrador.
echo.

REM Verificar se está sendo executado como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERRO: Este script precisa ser executado como administrador.
    echo Por favor, clique com o botao direito e selecione "Executar como administrador".
    pause
    exit /b 1
)

echo Verificando drivers ODBC instalados...
echo.

REM Verificar driver SQL Server
echo Verificando driver ODBC para SQL Server...
reg query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers" /v "ODBC Driver 17 for SQL Server" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Driver ODBC 17 para SQL Server ja esta instalado.
) else (
    echo Driver ODBC 17 para SQL Server nao encontrado.
    echo.
    echo Por favor, baixe e instale o driver ODBC para SQL Server:
    echo https://go.microsoft.com/fwlink/?linkid=2249006
    echo.
    echo Apos a instalacao, execute este script novamente.
    start https://go.microsoft.com/fwlink/?linkid=2249006
)

REM Verificar driver SQL Server 18
echo Verificando driver ODBC 18 para SQL Server...
reg query "HKLM\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers" /v "ODBC Driver 18 for SQL Server" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Driver ODBC 18 para SQL Server ja esta instalado.
    echo.
    echo ATENCAO: O Driver ODBC 18 requer configuracao adicional para evitar erros de certificado SSL.
    echo Ao configurar a conexao ODBC, marque a opcao "Confiar no certificado do servidor"
    echo ou selecione "Opcional" na configuracao de criptografia.
    echo.
    echo Para mais detalhes, consulte o arquivo CONFIGURACAO_ODBC.txt.
)

echo.
echo Verificacao concluida.
echo.

echo Para configurar as fontes de dados ODBC:
echo 1. Abra o Administrador de Fontes de Dados ODBC (odbcad32.exe)
echo 2. Na aba "DSN de Sistema", clique em "Adicionar"
echo 3. Selecione o driver apropriado e configure a conexao
echo.
echo IMPORTANTE: Se estiver usando o ODBC Driver 18 para SQL Server:
echo - Marque a opcao "Confiar no certificado do servidor" (Trust server certificate)
echo - OU selecione "Opcional" na opcao de criptografia
echo - Caso contrario, podera ocorrer o erro: "A cadeia de certificacao foi emitida
echo   por uma autoridade que nao e de confianca"
echo.

echo Deseja abrir o Administrador de Fontes de Dados ODBC agora? (S/N)
set /p resposta=

if /i "%resposta%"=="S" (
    start odbcad32.exe
)

echo.
echo Processo concluido.
echo.

pause