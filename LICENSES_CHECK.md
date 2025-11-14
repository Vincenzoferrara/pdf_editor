# Verifica Licenze Plugin - Editor PDF

## ✅ Plugin Opensource Conformi (MIT/Apache/BSD)

### PDF & Visualizzazione
- **pdfrx** - MIT License ✅ (Android, iOS, Windows, macOS, Linux, Web)
- **pdf** - Apache 2.0 ✅ (Cross-platform)
- **pdf_combiner** - MIT License ✅ (Android, iOS, Windows, macOS, Linux)
- **printing** - BSD 3-Clause ✅ (Cross-platform)

### State Management
- **flutter_riverpod** - MIT License ✅
- **riverpod_annotation** - MIT License ✅

### Navigation & UI
- **go_router** - BSD 3-Clause ✅
- **animations** - BSD 3-Clause ✅
- **flutter_staggered_animations** - MIT License ✅
- **dynamic_color** - Apache 2.0 ✅
- **flutter_colorpicker** - MIT License ✅

### File & Storage
- **file_picker** - MIT License ✅ (Android, iOS, Web, macOS, Linux, Windows)
- **path_provider** - BSD 3-Clause ✅
- **shared_preferences** - BSD 3-Clause ✅
- **permission_handler** - MIT License ✅

### OCR & Image Processing
- **google_ml_kit** - MIT License ✅
- **image** - Apache 2.0 ✅
- **flutter_image_compress** - MIT License ✅

### Drawing & Annotations
- **signature** - MIT License ✅
- **perfect_freehand** - MIT License ✅

### Text & Editing
- **flutter_quill** - MIT License ✅

### Utilities
- **crypto** - BSD 3-Clause ✅
- **equatable** - MIT License ✅
- **path** - BSD 3-Clause ✅
- **uuid** - MIT License ✅
- **window_manager** - MIT License ✅

## ❌ Plugin NON Opensource / Licenza Proprietaria

### PDF (Syncfusion)
- **syncfusion_flutter_pdf** - ❌ Licenza Commerciale Syncfusion
  - Richiede licenza Community (< $1M fatturato, < 5 dev) o Commercial
  - NON è opensource
  - **AZIONE RICHIESTA:** Sostituire con alternative opensource

- **syncfusion_flutter_pdfviewer** - ❌ Licenza Commerciale Syncfusion
  - Stessi requisiti di syncfusion_flutter_pdf
  - **AZIONE RICHIESTA:** Sostituire con `pdfrx` (già installato, MIT)

## 🔄 Azioni Necessarie

1. **Rimuovere Syncfusion**:
   - syncfusion_flutter_pdf
   - syncfusion_flutter_pdfviewer

2. **Sostituire con**:
   - **pdfrx** (MIT) - per viewing e manipolazione
   - **pdf** (Apache 2.0) - per creazione e editing avanzato
   - **pdf_combiner** (MIT) - per merge PDFs

3. **Benefici**:
   - 100% opensource (MIT/Apache/BSD)
   - Nessun vincolo di licenza
   - Cross-platform completo
   - Costo zero

## Verifica Compatibilità Piattaforme

Tutti i plugin principali supportano:
- ✅ Android
- ✅ iOS
- ✅ Linux
- ✅ macOS
- ✅ Windows
- ⚠️  Web (non richiesto dal progetto)
