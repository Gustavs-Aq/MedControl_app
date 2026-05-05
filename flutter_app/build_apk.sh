#!/bin/bash
# ==========================================================
#  build_apk.sh  –  MedControl APK Builder
#  Rode este script dentro da pasta flutter_app/
#  Uso: bash build_apk.sh
# ==========================================================

set -e  # Para se qualquer comando falhar

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     MedControl APK Builder           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# ── 1. Verificar Flutter ──────────────────────────────────
echo -e "${YELLOW}[1/6] Verificando Flutter...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter não encontrado!${NC}"
    echo "   Instale em: https://flutter.dev/docs/get-started/install"
    exit 1
fi
flutter --version
echo -e "${GREEN}✅ Flutter encontrado${NC}"

# ── 2. Verificar Android SDK ──────────────────────────────
echo ""
echo -e "${YELLOW}[2/6] Verificando Android SDK...${NC}"
if ! flutter doctor | grep -q "Android toolchain"; then
    echo -e "${RED}❌ Android SDK não configurado corretamente${NC}"
    echo "   Execute: flutter doctor"
    echo "   E siga as instruções para instalar o Android SDK"
    exit 1
fi
echo -e "${GREEN}✅ Android SDK OK${NC}"

# ── 3. Instalar dependências ──────────────────────────────
echo ""
echo -e "${YELLOW}[3/6] Instalando dependências (flutter pub get)...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependências instaladas${NC}"

# ── 4. Limpar build anterior ──────────────────────────────
echo ""
echo -e "${YELLOW}[4/6] Limpando build anterior...${NC}"
flutter clean
flutter pub get
echo -e "${GREEN}✅ Limpeza concluída${NC}"

# ── 5. Gerar keystore (se não existir) ───────────────────
echo ""
echo -e "${YELLOW}[5/6] Verificando assinatura do APK...${NC}"

KEYSTORE_DIR="android/app"
KEYSTORE_FILE="$KEYSTORE_DIR/medcontrol-key.jks"
KEY_PROPS="android/key.properties"

if [ ! -f "$KEYSTORE_FILE" ]; then
    echo "   Gerando keystore para assinatura..."
    keytool -genkey -v \
        -keystore "$KEYSTORE_FILE" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -alias medcontrol \
        -dname "CN=MedControl, OU=Dev, O=MedControl, L=BR, S=SP, C=BR" \
        -storepass medcontrol123 \
        -keypass medcontrol123

    cat > "$KEY_PROPS" << EOF
storePassword=medcontrol123
keyPassword=medcontrol123
keyAlias=medcontrol
storeFile=medcontrol-key.jks
EOF
    echo -e "${GREEN}✅ Keystore criado em $KEYSTORE_FILE${NC}"
else
    echo -e "${GREEN}✅ Keystore já existe${NC}"
fi

# ── 6. Build APK ──────────────────────────────────────────
echo ""
echo -e "${YELLOW}[6/6] Compilando APK...${NC}"
echo ""

# APK de release (menor e otimizado para instalação)
flutter build apk --release --split-per-abi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ APK GERADO COM SUCESSO!              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📦 Arquivos gerados:${NC}"
echo ""
ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null || \
ls -lh build/app/outputs/apk/release/*.apk 2>/dev/null

echo ""
echo -e "${BLUE}📱 Como instalar no celular:${NC}"
echo "   1. Habilite 'Fontes desconhecidas' no Android"
echo "      Configurações → Segurança → Instalar apps desconhecidos"
echo ""
echo "   2. Copie o APK para o celular via USB ou cabo"
echo "      O arquivo arm64-v8a é para celulares modernos (recomendado)"
echo ""
echo "   3. No celular, abra o arquivo .apk e instale"
echo ""
echo -e "${YELLOW}💡 Dica: Use o APK arm64-v8a para a maioria dos celulares Android modernos${NC}"
echo ""
