#!/usr/bin/env bash
# patch-identitaet.sh - stellt einen Fluux-Checkout auf Toms eigene iOS-Identitaet um
# Version: 1.0.0
# Datum: 2026-10-23
#
# Upstream signiert als net.processone.fluux (Team ProcessOne). Fuer den eigenen TestFlight-Build
# (Team 6KT29U932V) braucht es eine eigene Kennung. Alles Uebrige (Erweiterungen, App-Gruppe,
# Keychain-Gruppen, URL-Schema) leitet project.yml aus app.identifier ab.
# Jede Ersetzung muss genau greifen, sonst Abbruch - so faellt eine Upstream-Aenderung sofort auf.
# Aufruf im Wurzelverzeichnis des Checkouts: bash toms/patch-identitaet.sh one.mydc.fluux
set -euo pipefail
NEU="${1:?Kennung angeben, z. B. one.mydc.fluux}"
ALT=net.processone.fluux

ersetze() { # datei muster ersatz
  local f=$1 m=$2 r=$3
  grep -qF -- "$m" "$f" || { echo "FEHLER: '$m' nicht in $f - Upstream hat sich geaendert" >&2; exit 1; }
  python3 - "$f" "$m" "$r" <<'PY'
import sys; f,m,r=sys.argv[1:]; s=open(f).read(); open(f,'w').write(s.replace(m,r,1))
PY
  echo "  $f: $m -> $r"
}

ersetze apps/fluux/src-tauri/tauri.ios.conf.json "\"identifier\": \"$ALT\"" "\"identifier\": \"$NEU\""
# URL-Schema der Haupt-App (Share-Erweiterung oeffnet die App darueber)
ersetze apps/fluux/src-tauri/tauri.conf.json "\"$ALT\"
          ]," "\"$ALT\",
            \"$NEU\"
          ],"
ersetze apps/fluux/src/utils/shortcutConversation.ts "['$ALT:'," "['$NEU:', '$ALT:',"
# Pruefungen des TestFlight-Skripts
ersetze apps/fluux/scripts/tauri-ios-testflight.mjs "const BUNDLE_ID = '$ALT'" "const BUNDLE_ID = '$NEU'"
ersetze apps/fluux/scripts/tauri-ios-testflight.mjs "const APP_GROUP = 'group.$ALT.share'" "const APP_GROUP = 'group.$NEU.share'"
echo "Identitaet: $NEU"
