@echo off
REM ==========================================================
REM  build_apk.bat  –  MedControl APK Builder para Windows
REM  Rode este script dentro da pasta flutter_app/
REM  Uso: build_apk.bat
REM ==========================================================

echo.
echo  ╔══════════════════════════════════════╗
echo  ║     MedControl APK Builder           ║
echo  ╚══════════════════════════════════════╝
echo.

REM ── 1. Verificar Flutter ──────────────────────────────────
echo [1/5] Verificando Flutter...
flutter --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERRO: Flutter nao encontrado!
    echo Instale em: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
flutter --version
echo Flutter encontrado OK

REM ── 2. Instalar dependencias ──────────────────────────────
echo.
echo [2/5] Instalando dependencias...
call flutter pub get
IF %ERRORLEVEL% NEQ 0 (
    echo ERRO: Falha ao instalar dependencias
    pause
    exit /b 1
)
echo Dependencias OK

REM ── 3. Limpar build anterior ──────────────────────────────
echo.
echo [3/5] Limpando build anterior...
call flutter clean
call flutter pub get
echo Limpeza OK

REM ── 4. Verificar keystore ─────────────────────────────────
echo.
echo [4/5] Verificando keystore...
IF NOT EXIST "android\app\medcontrol-key.jks" (
    echo Gerando keystore...
    keytool -genkey -v ^
        -keystore android\app\medcontrol-key.jks ^
        -keyalg RSA ^
        -keysize 2048 ^
        -validity 10000 ^
        -alias medcontrol ^
        -dname "CN=MedControl, OU=Dev, O=MedControl, L=BR, S=SP, C=BR" ^
        -storepass medcontrol123 ^
        -keypass medcontrol123

    echo storePassword=medcontrol123 > android\key.properties
    echo keyPassword=medcontrol123 >> android\key.properties
    echo keyAlias=medcontrol >> android\key.properties
    echo storeFile=medcontrol-key.jks >> android\key.properties

    echo Keystore criado!
) ELSE (
    echo Keystore ja existe
)

REM ── 5. Build APK ──────────────────────────────────────────
echo.
echo [5/5] Compilando APK (aguarde alguns minutos)...
call flutter build apk --release --split-per-abi
IF %ERRORLEVEL% NEQ 0 (
    echo ERRO: Falha ao compilar APK
    echo Execute: flutter doctor
    pause
    exit /b 1
)

echo.
echo  ╔══════════════════════════════════════════╗
echo  ║       APK GERADO COM SUCESSO!            ║
echo  ╚══════════════════════════════════════════╝
echo.
echo APKs gerados em: build\app\outputs\flutter-apk\
echo.
dir build\app\outputs\flutter-apk\*.apk
echo.
echo Como instalar no celular:
echo  1. Habilite "Fontes desconhecidas" em Configuracoes -^> Seguranca
echo  2. Copie o APK arm64-v8a para o celular (recomendado para modernos)
echo  3. Abra o .apk no celular e instale
echo.
pause
