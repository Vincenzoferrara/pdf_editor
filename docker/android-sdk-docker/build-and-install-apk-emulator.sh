#!/bin/bash
# Script per compilare e installare l'APK Android su emulatore

set -e  # Esce in caso di errore

# Colori per output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}  Flutter APK Build & Install${NC}"
echo -e "${BLUE}  PDF Editor App - Emulator${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# Immagine Docker standard
IMAGE_NAME="instrumentisto/flutter"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk"

# Step 1: Compilazione APK debug
echo -e "${BLUE}[1/3] Compilazione APK debug...${NC}"
echo -e "Pulizia cache e sincronizzazione dipendenze..."
docker run \
    -v "$PROJECT_ROOT:/app:rw" \
    -w /app \
    -t \
    $IMAGE_NAME \
    sh -c "flutter build apk --debug -v"

# Verifica che l'APK sia stato creato
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}✗ Errore: APK non trovato${NC}"
    exit 1
fi

echo -e "${GREEN}✓ APK compilato con successo${NC}"
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "Dimensione: ${BLUE}$APK_SIZE${NC}"

# Step 2: Avvio emulatore (se necessario)
echo ""
echo -e "${BLUE}[2/3] Verifica emulatore...${NC}"

# Verifica che adb sia disponibile
if ! command -v adb &> /dev/null; then
    echo -e "${RED}✗ Errore: adb non trovato${NC}"
    exit 1
fi

# Verifica se emulatore è già in esecuzione
EMULATOR_RUNNING=$(adb devices | grep emulator | wc -l)
if [ "$EMULATOR_RUNNING" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Nessun emulatore in esecuzione${NC}"
    echo -e "${YELLOW}Avvia un emulatore Android e riprova${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Emulatore già in esecuzione${NC}"
fi

# Step 3: Installazione su emulatore
echo ""
echo -e "${BLUE}[3/3] Installazione su emulatore...${NC}"

# Trova l'emulatore
EMULATOR_ID=$(adb devices | grep emulator | awk '{print $1}' | head -1)
if [ -z "$EMULATOR_ID" ]; then
    echo -e "${RED}✗ Nessun emulatore trovato${NC}"
    exit 1
fi

echo -e "Emulatore: ${BLUE}$EMULATOR_ID${NC}"

# Disinstalla vecchia versione se presente
echo ""
echo -e "Rimozione versione precedente (se presente)..."
adb -s "$EMULATOR_ID" uninstall editor_pdf 2>/dev/null || echo "Nessuna versione precedente trovata"

# Installa l'APK
echo ""
echo -e "Installazione APK su emulatore..."
adb -s "$EMULATOR_ID" install "$APK_PATH"

echo ""
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}✓ Installazione completata!${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo -e "APK installato da:"
echo -e "${BLUE}$APK_PATH${NC}"
echo ""
