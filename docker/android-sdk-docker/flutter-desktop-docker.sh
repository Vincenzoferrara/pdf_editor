#!/bin/bash
# Script per compilare applicazione Flutter desktop usando Docker

set -e  # Esce in caso di errore

# Colori per output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}  Flutter Desktop Docker Build${NC}"
echo -e "${BLUE}  PDF Editor App${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# Immagine Docker standard
IMAGE_NAME="instrumentisto/flutter"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Step 1: Compilazione desktop
echo -e "${BLUE}[1/2] Compilazione applicazione desktop...${NC}"
echo -e "Pulizia cache e sincronizzazione dipendenze..."
docker run \
    -v "$PROJECT_ROOT:/app:rw" \
    -w /app \
    -t \
    $IMAGE_NAME \
    sh -c "flutter pub get && flutter build linux --release -v"

# Verifica che l'eseguibile sia stato creato
BUNDLE_PATH="$PROJECT_ROOT/build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE_PATH" ]; then
    echo -e "${RED}✗ Errore: Bundle desktop non trovato${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Applicazione desktop compilata con successo${NC}"
BUNDLE_SIZE=$(du -sh "$BUNDLE_PATH" | cut -f1)
echo -e "Dimensione: ${BLUE}$BUNDLE_SIZE${NC}"

# Step 2: Info esecuzione
echo ""
echo -e "${BLUE}[2/2] Build completata${NC}"

echo ""
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}✓ Compilazione completata!${NC}"
echo -e "${GREEN}====================================${NC}"
echo ""
echo -e "Bundle disponibile in:"
echo -e "${BLUE}$BUNDLE_PATH${NC}"
echo ""
echo -e "${YELLOW}Per avviare l'app:${NC}"
echo -e "${BLUE}cd $BUNDLE_PATH && ./editor_pdf${NC}"
echo ""
