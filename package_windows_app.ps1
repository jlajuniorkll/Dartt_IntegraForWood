# Script para empacotar o aplicativo Windows com todas as dependências

# Definir variáveis
$appName = "DarttIntegraForwood"
$version = "1.0.0"
$releaseDir = "build\windows\x64\runner\Release"
$outputDir = "dist"
$packageDir = "$outputDir\$appName-$version"

# Criar diretórios de saída
Write-Host "Criando diretórios de saída..."
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $packageDir | Out-Null

# Copiar arquivos do aplicativo
Write-Host "Copiando arquivos do aplicativo..."
Copy-Item -Path "$releaseDir\*" -Destination $packageDir -Recurse

# Criar diretório para drivers ODBC
New-Item -ItemType Directory -Force -Path "$packageDir\odbc_drivers" | Out-Null

# Criar arquivo README com instruções
$readmeContent = @"
# DarttIntegraForwood $version

## Requisitos do Sistema
- Windows 10 ou superior
- Microsoft Visual C++ Redistributable 2019 ou superior
- Drivers ODBC para SQL Server e PostgreSQL

## Instalação

1. Extraia todos os arquivos para uma pasta de sua escolha
2. Instale os drivers ODBC necessários da pasta 'odbc_drivers' (se não estiverem instalados)
3. Configure suas conexões ODBC no Administrador de Fontes de Dados ODBC do Windows
4. Execute o arquivo 'dartt_integraforwood.exe'

## Configuração

Na primeira execução, acesse as configurações do aplicativo para definir:
- Conexões com bancos de dados (SQL Server e PostgreSQL)
- Diretórios de trabalho (XML, ESP)
- Códigos de batismo e outros parâmetros

## Suporte

Para suporte, entre em contato com o desenvolvedor.
"@

$readmeContent | Out-File -FilePath "$packageDir\README.txt" -Encoding utf8

# Criar arquivo de atalho para o executável
$shortcutPath = "$packageDir\$appName.lnk"
$targetPath = "$packageDir\dartt_integraforwood.exe"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetPath
$Shortcut.Save()

# Criar arquivo batch para verificar e instalar dependências
$batchContent = @"
@echo off
echo Verificando dependências do sistema...

REM Verificar Visual C++ Redistributable
echo Verificando Microsoft Visual C++ Redistributable...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Microsoft Visual C++ Redistributable não encontrado.
    echo Por favor, instale o Microsoft Visual C++ Redistributable 2019 ou superior.
    pause
    exit /b 1
)

REM Verificar ODBC
echo Verificando ODBC...
if not exist C:\Windows\System32\odbcad32.exe (
    echo ODBC não encontrado.
    echo Por favor, instale o ODBC.
    pause
    exit /b 1
)

echo Todas as dependências verificadas com sucesso!
echo Iniciando o aplicativo...

start "" "%~dp0dartt_integraforwood.exe"
"@

$batchContent | Out-File -FilePath "$packageDir\start_app.bat" -Encoding ascii

# Criar arquivo ZIP com todos os arquivos
Write-Host "Criando arquivo ZIP..."
$zipPath = "$outputDir\$appName-$version.zip"
Compress-Archive -Path $packageDir\* -DestinationPath $zipPath -Force

Write-Host "Pacote criado com sucesso: $zipPath"
Write-Host "Diretório do pacote: $packageDir"