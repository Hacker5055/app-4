#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Canary Duress Lock — native APK build (no Gradle, no Flutter engine required)
#
# Produces a signed, installable APK from the Kotlin sources in native/src.
# Only the Android SDK build-tools + a JDK + the Kotlin compiler are needed.
#
# Required environment:
#   JAVA_HOME      JDK 17
#   ANDROID_JAR    <sdk>/platforms/android-34/android.jar
#   BUILD_TOOLS    <sdk>/build-tools/34.0.0
#   KOTLINC        path to the kotlinc executable (dir must contain ../lib/kotlin-stdlib.jar)
#
# Usage:  ./build.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/build"
VERSION_NAME="${VERSION_NAME:-1.0.0}"
VERSION_CODE="${VERSION_CODE:-1}"
APP_NAME="CanaryDuressLock-v${VERSION_NAME}"

: "${JAVA_HOME:?set JAVA_HOME to a JDK 17 install}"
: "${ANDROID_JAR:?set ANDROID_JAR to platforms/android-34/android.jar}"
: "${BUILD_TOOLS:?set BUILD_TOOLS to the build-tools directory}"
: "${KOTLINC:?set KOTLINC to the kotlinc executable}"

JAVA="$JAVA_HOME/bin/java"
KOTLIN_STDLIB="$(cd "$(dirname "$KOTLINC")/../lib" && pwd)/kotlin-stdlib.jar"
# apksigner / zipalign wrappers expect `java` on PATH
export PATH="$JAVA_HOME/bin:$PATH"

step() { printf '\n\033[1;32m▸ %s\033[0m\n' "$1"; }

rm -rf "$OUT"
mkdir -p "$OUT/classes" "$OUT/gen"

step "1/7  compiling resources (aapt2 compile)"
"$BUILD_TOOLS/aapt2" compile --dir "$HERE/res" -o "$OUT/compiled.zip"

step "2/7  linking resources + manifest (aapt2 link)"
"$BUILD_TOOLS/aapt2" link \
  -o "$OUT/unsigned.apk" \
  -I "$ANDROID_JAR" \
  --manifest "$HERE/AndroidManifest.xml" \
  --java "$OUT/gen" \
  --min-sdk-version 23 \
  --target-sdk-version 34 \
  --version-code "$VERSION_CODE" \
  --version-name "$VERSION_NAME" \
  --auto-add-overlay \
  "$OUT/compiled.zip"

step "3/7  compiling Kotlin sources (kotlinc)"
SRC_FILES=$(find "$HERE/src" -name '*.kt' | sort)
# shellcheck disable=SC2086
"$KOTLINC" \
  -classpath "$ANDROID_JAR" \
  -jvm-target 1.8 \
  -nowarn \
  -d "$OUT/classes" \
  $SRC_FILES

step "4/7  dexing (d8, min-api 23)"
CLASS_FILES=$(find "$OUT/classes" -name '*.class' | sort)
# R8 prints harmless "malformed kotlin.Metadata" notices for the stdlib 2.x jars;
# they are filtered out of the log below, real failures are still reported.
# shellcheck disable=SC2086
if ! "$JAVA" -cp "$BUILD_TOOLS/lib/d8.jar" com.android.tools.r8.D8 \
  --release \
  --min-api 23 \
  --lib "$ANDROID_JAR" \
  --output "$OUT" \
  $CLASS_FILES \
  "$KOTLIN_STDLIB" > "$OUT/d8.log" 2>&1; then
  echo "d8 failed:"
  grep -vE "malformed kotlin.Metadata|Unexpected error during rewriting|Should never be called|^\s+at " "$OUT/d8.log" | tail -30
  exit 1
fi
echo "  dexed $(find "$OUT/classes" -name '*.class' | wc -l) classes (+ kotlin-stdlib)"

step "5/7  packaging classes.dex into the APK"
( cd "$OUT" && zip -q -j unsigned.apk classes.dex )

step "6/7  aligning (zipalign 4-byte page alignment)"
"$BUILD_TOOLS/zipalign" -f -p 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"

step "7/7  signing (apksigner, v1+v2)"
KEYSTORE="${KEYSTORE_PATH:-$OUT/canary-release.jks}"
if [ ! -f "$KEYSTORE" ]; then
  echo "  generating demo keystore at $KEYSTORE"
  "$JAVA_HOME/bin/keytool" -genkeypair \
    -keystore "$KEYSTORE" \
    -storepass "${KEYSTORE_PASSWORD:-canary2026}" \
    -keypass "${KEY_PASSWORD:-canary2026}" \
    -alias "${KEY_ALIAS:-canary}" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Canary Duress Lock, O=Canary Security, C=EG" >/dev/null 2>&1
fi

"$BUILD_TOOLS/apksigner" sign \
  --ks "$KEYSTORE" \
  --ks-pass "pass:${KEYSTORE_PASSWORD:-canary2026}" \
  --key-pass "pass:${KEY_PASSWORD:-canary2026}" \
  --v1-signing-enabled true \
  --v2-signing-enabled true \
  --out "$OUT/$APP_NAME.apk" \
  "$OUT/aligned.apk"

"$BUILD_TOOLS/apksigner" verify --verbose "$OUT/$APP_NAME.apk" | sed 's/^/  /'

printf '\n\033[1;32m✔ APK ready:\033[0m %s\n' "$OUT/$APP_NAME.apk"
ls -lh "$OUT/$APP_NAME.apk"
