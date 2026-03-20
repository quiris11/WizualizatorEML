#!/usr/bin/env bash
# setup-macos.sh — instaluje Wizualizator EML na macOS
#
# Użycie:
#   chmod +x setup-macos.sh && ./setup-macos.sh
#
# Wymagania: Xcode Command Line Tools (xcode-select --install)
# Opcjonalne: brew install duti

set -euo pipefail

SCRIPT_SRC="./eml-gmail.sh"
TEMPLATE_SRC="./EML-Gmail.html"

APP_NAME="Wizualizator EML"
APP_DIR="$HOME/Applications/${APP_NAME}.app"
TEMPLATE_DEST="/usr/local/share/eml-gmail/index.html"
BIN_DEST="/usr/local/bin/eml-gmail"
BUNDLE_ID="local.eml-gmail"

# ── Sprawdzenie plików źródłowych ──
[[ ! -f "$SCRIPT_SRC" ]]   && { echo "Błąd: brak $SCRIPT_SRC"   >&2; exit 1; }
[[ ! -f "$TEMPLATE_SRC" ]] && { echo "Błąd: brak $TEMPLATE_SRC" >&2; exit 1; }

# ── Sprawdzenie zależności ──
echo "▶ Sprawdzanie zależności…"

if ! command -v python3 &>/dev/null; then
    echo "Błąd: python3 niedostępny." >&2
    echo "  Zainstaluj: xcode-select --install  lub  brew install python3" >&2
    exit 1
fi
echo "  ✔ python3: $(python3 --version)"

if ! command -v osacompile &>/dev/null; then
    echo "Błąd: osacompile niedostępny." >&2
    echo "  Zainstaluj: xcode-select --install" >&2
    exit 1
fi
echo "  ✔ osacompile: dostępny"

# ── Instalacja szablonu HTML ──
echo "▶ Instalacja szablonu HTML → $TEMPLATE_DEST"
sudo mkdir -p "$(dirname "$TEMPLATE_DEST")"
sudo cp "$TEMPLATE_SRC" "$TEMPLATE_DEST"
sudo chmod 644 "$TEMPLATE_DEST"
echo "  ✔ Szablon zainstalowany"

# ── Instalacja skryptu CLI ──
echo "▶ Instalacja skryptu CLI → $BIN_DEST"
sudo cp "$SCRIPT_SRC" "$BIN_DEST"
sudo chmod +x "$BIN_DEST"
echo "  ✔ Skrypt zainstalowany"

# ── Usuń starą wersję aplikacji ──
[[ -d "$APP_DIR" ]] && { rm -rf "$APP_DIR"; echo "  ✔ Usunięto starą wersję"; }

# ── Utwórz AppleScript z obsługą on open ──
# UWAGA: shell script w .app NIE otrzymuje pliku jako $1.
# macOS przekazuje plik przez Apple Events — tylko AppleScript obsługuje "on open" niezawodnie.
echo "▶ Kompilacja aplikacji AppleScript…"

TMP_AS="/tmp/eml-gmail-$$.as"  # PID-based — pewniejsze niż mktemp z suffixem na macOS
cat > "$TMP_AS" << 'ASEOF'
on run
    display notification "Otworz plik .eml dwuklikiem lub przeciagnij na ikone" with title "Wizualizator EML"
end run

on open dropped_files
    repeat with f in dropped_files
        set fp to POSIX path of f
        do shell script "/usr/local/bin/eml-gmail " & quoted form of fp
    end repeat
    tell me to quit
end open
ASEOF

osacompile -o "$APP_DIR" "$TMP_AS"
rm -f "$TMP_AS" 2>/dev/null || true
echo "  ✔ Aplikacja skompilowana: $APP_DIR"

# ── Zaktualizuj Info.plist przez Python ──
echo "▶ Konfiguracja Info.plist…"

python3 - "$APP_DIR" << 'PYEOF'
import plistlib, os, sys
app_dir = sys.argv[1]
plist_path = os.path.join(app_dir, "Contents", "Info.plist")
with open(plist_path, "rb") as f:
    plist = plistlib.load(f)
plist["CFBundleName"]            = "Wizualizator EML"
plist["CFBundleDisplayName"]     = "Wizualizator EML"
plist["CFBundleIdentifier"]      = "local.eml-gmail"
plist["NSHighResolutionCapable"] = True
plist["LSMinimumSystemVersion"]  = "11.0"
plist["CFBundleDocumentTypes"]   = [{
    "CFBundleTypeName":       "Email Message",
    "CFBundleTypeRole":       "Viewer",
    "LSHandlerRank":          "Alternate",
    "CFBundleTypeExtensions": ["eml", "msg"],
    "CFBundleTypeMIMETypes":  ["message/rfc822", "application/vnd.ms-outlook"],
    "LSItemContentTypes":     ["com.apple.mail.email", "public.email-message"],
}]
with open(plist_path, "wb") as f:
    plistlib.dump(plist, f)
print("  ✔ Info.plist zaktualizowany")
PYEOF

# ── Usuń quarantine (Gatekeeper) ──
xattr -cr "$APP_DIR" 2>/dev/null && echo "  ✔ Usunięto atrybut kwarantanny" || true

# ── Ad-hoc podpisanie (wymagane macOS Ventura+) ──
if command -v codesign &>/dev/null; then
    if codesign --force --deep --sign - "$APP_DIR" 2>/dev/null; then
        echo "  ✔ Ad-hoc podpisanie (codesign --sign -)"
    else
        echo "  ⚠  codesign nie powiodło się — spróbuj ręcznie:"
        echo "     codesign --force --deep --sign - \"$APP_DIR\""
    fi
fi

# ── Rejestracja w Launch Services ──
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -f "$APP_DIR"
    echo "  ✔ Zarejestrowano w Launch Services"
fi

# ── Ustaw jako domyślną aplikację ──
if command -v duti &>/dev/null; then
    duti -s "$BUNDLE_ID" com.apple.mail.email all
    duti -s "$BUNDLE_ID" .eml all
    echo "  ✔ Ustawiono jako domyślną aplikację dla .eml"
else
    echo ""
    echo "  ⚠  duti nie jest zainstalowane."
    echo "     CLI:  brew install duti && duti -s $BUNDLE_ID .eml all"
    echo "     GUI:  PPM na plik .eml → Otwórz za pomocą → Inna aplikacja"
    echo "           → $APP_DIR → Zawsze otwieraj"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✔  Instalacja zakończona!                   ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Aplikacja : $APP_DIR"
echo "║  Szablon   : $TEMPLATE_DEST"
echo "║  CLI       : $BIN_DEST"
echo "╠══════════════════════════════════════════════╣"
echo "║  Test: otwórz dowolny plik .eml w Finderze   ║"
echo "║  CLI:  eml-gmail ~/plik.eml                  ║"
echo "╚══════════════════════════════════════════════╝"
