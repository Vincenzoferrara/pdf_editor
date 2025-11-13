# Flutter Android Builder - Docker

Ambiente Docker completo per compilare APK Android senza installare SDK locali.

## Cosa include

- **Ubuntu 22.04** - Base stabile
- **Java 21** - Richiesto da Gradle/Kotlin
- **Flutter 3.35.7** - Versione stabile
- **Android SDK**:
  - Platform Tools (adb, fastboot)
  - Platforms: 33, 34, 35, 36
  - Build Tools: 34.0.0, 35.0.1
- **Android NDK 28.2.13676358** - Per codice nativo C/C++
- **CMake 3.22.1** - Per compilare progetti NDK

## Utilizzo rapido

### 1. Compilare e installare su dispositivo USB

```bash
cd docker/android-sdk-docker
./build-and-install-apk.sh
```

### 2. Compilare e installare su emulatore Android

```bash
cd docker/android-sdk-docker
./build-and-install-apk-emulator.sh
```

### 3. Compilare applicazione desktop Linux

```bash
cd docker/android-sdk-docker
./flutter-desktop-docker.sh
```

**Prima volta**: Scarica l'immagine Docker (può richiedere alcuni minuti)
**Volte successive**: Usa la cache, molto più veloce!

L'APK sarà in: `build/app/outputs/flutter-apk/app-debug.apk`

## Utilizzo da VSCode

Le configurazioni sono già pronte in `.vscode/`:

1. **Premi F5** e scegli:
   - "1. Flutter Desktop" - Debug desktop normale
   - "2. Flutter Android USB" - Compila e installa su dispositivo USB
   - "3. Flutter Android Virtual" - Compila e installa su emulatore

2. **Task disponibili** (Ctrl+Shift+P → "Tasks: Run Task"):
   - Build App Linux
   - Clean & Build
   - Flutter Pub Get
   - Flutter Analyze

## Comandi utili

```bash
# Vedere le immagini Docker
docker images | grep flutter

# Rimuovere l'immagine
docker rmi instrumentisto/flutter

# Vedere spazio occupato
docker images instrumentisto/flutter --format "{{.Size}}"
```

## Troubleshooting

### Errore di permessi sui file generati

I file creati dal container appartengono all'utente UID 1000. Se il tuo utente è diverso:

```bash
sudo chown -R $(id -u):$(id -g) build/
```

### Build fallisce con "Out of memory"

Aumenta la memoria disponibile per Docker:
- Docker Desktop: Settings → Resources → Memory (min 4GB)
- Linux: Modifica `/etc/docker/daemon.json`

## Struttura file

```
android-sdk-docker/
├── build-and-install-apk.sh          # Script per USB
├── build-and-install-apk-emulator.sh # Script per emulatore
├── flutter-desktop-docker.sh         # Script per desktop
├── .dockerignore                     # File da escludere
├── .gitignore                        # Git ignore
└── README.md                         # Questa guida
```

## Note

- **Immagine Docker**: Usa `instrumentisto/flutter` ufficiale
- **Cache Docker**: Le build successive sono molto più velche
- **Portabilità**: Funziona su qualsiasi sistema con Docker
- **Nessuna installazione locale**: Non serve Flutter/Android SDK sul PC

## Requisiti

- Docker installato
- Almeno 10 GB di spazio disco libero
- Per Android USB: adb installato (`/opt/android-sdk/platform-tools/adb`)
- Per Android emulator: Android SDK con emulatore configurato
- Connessione internet (solo per la prima build)
