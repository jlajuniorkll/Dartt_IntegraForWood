@echo off
echo Verificando depend??ncias do sistema...

REM Verificar Visual C++ Redistributable
echo Verificando Microsoft Visual C++ Redistributable...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Microsoft Visual C++ Redistributable n??o encontrado.
    echo Por favor, instale o Microsoft Visual C++ Redistributable 2019 ou superior.
    pause
    exit /b 1
)

REM Verificar ODBC
echo Verificando ODBC...
if not exist C:\Windows\System32\odbcad32.exe (
    echo ODBC n??o encontrado.
    echo Por favor, instale o ODBC.
    pause
    exit /b 1
)

echo Todas as depend??ncias verificadas com sucesso!
echo Iniciando o aplicativo...

start "" "%~dp0dartt_integraforwood.exe"
