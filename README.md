# Editor PDF

Un'applicazione Flutter per l'editing di PDF con funzionalità OCR, annotazioni e stampa.

## Caratteristiche

- 📄 Visualizzazione PDF con zoom e navigazione
- ✏️ Annotazioni e disegni sui documenti
- 🔍 Riconoscimento ottico dei caratteri (OCR)
- 🔐 Supporto per PDF protetti da password
- 🖨️ Stampa diretta dei documenti
- 🌙 Tema chiaro/scuro dinamico
- 📱 Interfaccia Material Design 3

## Prerequisiti

- Flutter SDK >=3.9.4
- Dart SDK >=3.9.4
- Linux/Windows/macOS per lo sviluppo desktop

## Installazione

1. Clona il repository:
```bash
git clone <repository-url>
cd app_editor_pdf
```

2. Installa le dipendenze:
```bash
flutter pub get
```

3. Configura l'ambiente desktop:
```bash
flutter config --enable-linux-desktop
# o per Windows
flutter config --enable-windows-desktop
# o per macOS
flutter config --enable-macos-desktop
```

## Sviluppo con VS Code

1. Installa le estensioni raccomandate (vedi `.vscode/extensions.json`)
2. Usa F5 per avviare l'app in modalità debug
3. Seleziona la configurazione di lancio dal menu Debug:
   - `Editor PDF (Debug)` - Sviluppo con debug
   - `Editor PDF (Release)` - Build di release
   - `Editor PDF (Profile)` - Build con profiling

## Struttura del Progetto

```
lib/
├── core/                  # Funzionalità core
│   ├── constants/         # Costanti dell'app
│   ├── theme/           # Temi e personalizzazione
│   └── utils/           # Utilità varie
├── data/                 # Data layer
│   ├── models/          # Modelli di dati
│   └── services/        # Servizi business logic
└── presentation/         # UI layer
    ├── pages/           # Pagine principali
    ├── providers/       # State management (Riverpod)
    └── widgets/         # Widget riutilizzabili
```

## Dipendenze Principali

- `flutter_riverpod` - State management
- `pdfx` - Visualizzazione PDF
- `google_ml_kit` - OCR e elaborazione immagini
- `printing` - Stampa documenti
- `go_router` - Navigazione
- `dynamic_color` - Temi dinamici

## Build per Desktop

### Linux
```bash
flutter build linux
```

### Windows
```bash
flutter build windows
```

### macOS
```bash
flutter build macos
```

## Note di Sviluppo

- L'app usa Riverpod per il state management
- Il routing è gestito con go_router
- Il tema segue Material Design 3 con dynamic color
- I file PDF vengono processati con pdfx
- L'OCR è implementato con Google ML Kit

## Licenza

MIT License
