@echo off
echo Copiando dependencias SSL para o aplicativo...
echo.

REM Verificar se as DLLs existem no sistema
if exist "C:\Windows\System32\msodbcsql18.dll" (
    echo Copiando msodbcsql18.dll...
    copy "C:\Windows\System32\msodbcsql18.dll" "%~dp0" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] msodbcsql18.dll copiado com sucesso
    ) else (
        echo [ERRO] Falha ao copiar msodbcsql18.dll
    )
) else (
    echo [AVISO] msodbcsql18.dll nao encontrado no sistema
)

REM Copiar Visual C++ Redistributable DLLs
if exist "C:\Windows\System32\msvcr120.dll" (
    echo Copiando msvcr120.dll...
    copy "C:\Windows\System32\msvcr120.dll" "%~dp0" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] msvcr120.dll copiado com sucesso
    )
) else (
    echo [AVISO] msvcr120.dll nao encontrado
)

if exist "C:\Windows\System32\msvcp120.dll" (
    echo Copiando msvcp120.dll...
    copy "C:\Windows\System32\msvcp120.dll" "%~dp0" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] msvcp120.dll copiado com sucesso
    )
) else (
    echo [AVISO] msvcp120.dll nao encontrado
)

REM Verificar se o ODBC Driver 17 esta disponivel como alternativa
if exist "C:\Windows\System32\msodbcsql17.dll" (
    echo Copiando msodbcsql17.dll (alternativa)...
    copy "C:\Windows\System32\msodbcsql17.dll" "%~dp0" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] msodbcsql17.dll copiado com sucesso
    )
) else (
    echo [INFO] ODBC Driver 17 nao encontrado (opcional)
)

echo.
echo Processo concluido!
echo.
echo PROXIMOS PASSOS:
echo 1. Execute o aplicativo para testar a conexao
echo 2. Se ainda nao funcionar, instale o Visual C++ Redistributable
echo 3. Considere usar ODBC Driver 17 se o 18 continuar com problemas
echo.
pause