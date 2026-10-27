# Native APK module — Canary Duress Lock

A **self-contained, installable Android build** of the same app, written in Kotlin against the
framework APIs only (no Flutter engine, no AndroidX, no Gradle). It exists because the Flutter
toolchain cannot be provisioned in every environment: the Flutter engine artifacts, the Dart SDK,
AGP and KGP are all fetched from hosts that restricted networks often block.

This module builds with nothing but:

* JDK 17 (`javac`, `keytool`)
* Android SDK build-tools (`aapt2`, `d8`, `apksigner`, `zipalign`)
* `android.jar` from platform 34
* the Kotlin compiler (`kotlinc`)

…and produces a signed, verifiable APK.

```
native/
├── AndroidManifest.xml          # BIND_DEVICE_ADMIN, BIND_ACCESSIBILITY_SERVICE, USE_BIOMETRIC
├── build.sh                     # aapt2 compile → link → kotlinc → d8 → zipalign → apksigner
├── res/                         # strings, theme, launcher icons, device-admin + a11y XML
└── src/com/canary/duresslock/
    ├── MainActivity.kt          # setup → locked → vault → decoy state machine
    ├── DuressEngine.kt          # SHA-256(pepper‖PIN) dual-PIN engine, purge orchestration
    ├── security/
    │   ├── KeyStoreManager.kt   # AES-256-GCM in StrongBox/TEE, deleteEntry() purge
    │   ├── MemoryZeroizer.kt    # multi-pass Arrays.fill with volatile barrier
    │   ├── DuressTriggerReceiver.kt
    │   ├── DeviceAdminReceiver.kt
    │   └── AccessibilityMonitorService.kt
    └── ui/
        ├── Theme.kt             # cyber-stealth palette + view helpers
        ├── Widgets.kt           # shield emblem, PIN dots, keypad key, cards, toggles
        ├── PinPad.kt            # 6-dot PIN entry + keypad
        ├── LockScreen.kt        # lock gate (identical for both PINs)
        ├── SetupScreen.kt       # first-launch wizard
        ├── VaultScreen.kt       # encrypted inventory + hardware status
        ├── DecoyScreen.kt       # calculator · notes · gallery · call log
        ├── DecoyCalculator.kt   # working arithmetic
        └── ConfigDialog.kt      # duress action, mock mode, device admin
```

## Build

```bash
export JAVA_HOME=/path/to/jdk-17
export ANDROID_JAR=$ANDROID_HOME/platforms/android-34/android.jar
export BUILD_TOOLS=$ANDROID_HOME/build-tools/34.0.0
export KOTLINC=/path/to/kotlin/bin/kotlinc

cd native && ./build.sh
# → native/build/CanaryDuressLock-v1.0.0.apk
```

Optional signing overrides: `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
Without them a throwaway keystore is generated inside `build/` (never committed).

## What is inside the shipped APK

| Capability | Where |
|---|---|
| Dual PIN (6 digits, SHA-256 + pepper), duress checked first | `DuressEngine.verify` |
| 5 failed attempts → timed lockout | `DuressEngine` + `LockScreen.startLockout` |
| Hardware key creation, StrongBox → TEE → software fallback | `KeyStoreManager.generateMasterKey` |
| Purge: `deleteEntry()` ×2 + verification + prefs wipe | `DuressEngine.executeDuress` |
| Multi-pass memory wipe (0x00 → 0xFF → 0x00) | `MemoryZeroizer.secureWipe` |
| Optional hard wipe (`wipeData(0)`) | `DuressEngine.triggerWipe` |
| Decoy: calculator, notes, gallery, fake call log | `ui/DecoyScreen.kt`, `ui/DecoyCalculator.kt` |
| Exit decoy: tap **Smart Tools** 5× | `DecoyScreen.onSecretTap` |
| Mock testing mode (default **on**) | `DuressEngine.isMockMode` |

The APK is pure DEX (no native libraries), so it installs on arm64-v8a, armeabi-v7a and x86_64
devices and emulators alike. `minSdk 23`, `targetSdk 34`.

## Verify

```bash
$BUILD_TOOLS/apksigner verify --verbose build/CanaryDuressLock-v1.0.0.apk
$BUILD_TOOLS/aapt2 dump badging build/CanaryDuressLock-v1.0.0.apk | head
```

## Differences from the Flutter app

The Flutter project in `lib/` remains the primary source of truth (richer UI, Hive storage,
`flutter_secure_storage`, biometric prompt). This native module reproduces the security-critical
behaviour and the complete user flow with framework views only, so an APK can be produced and
audited without the Flutter toolchain. The two share the same `security/` Kotlin sources.
