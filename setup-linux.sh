#!/usr/bin/env bash
# setup-linux.sh — instaluje Wizualizator EML na Linuksie
#
# Użycie:
#   chmod +x setup-linux.sh && ./setup-linux.sh
#
# Wymagania: bash, python3, xdg-utils, coreutils

set -euo pipefail

SCRIPT_SRC="./eml-gmail.sh"
TEMPLATE_SRC="./EML-Gmail.html"

BIN_DEST="/usr/local/bin/eml-gmail"
TEMPLATE_DEST="/usr/local/share/eml-gmail/index.html"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/eml-gmail.desktop"

# ── Sprawdzenie plików źródłowych ──
if [[ ! -f "$SCRIPT_SRC" ]]; then
    echo "Błąd: brak pliku skryptu: $SCRIPT_SRC" >&2
    exit 1
fi
if [[ ! -f "$TEMPLATE_SRC" ]]; then
    echo "Błąd: brak szablonu HTML: $TEMPLATE_SRC" >&2
    exit 1
fi

# ── Sprawdzenie zależności ──
echo "▶ Sprawdzanie zależności…"

if ! command -v python3 &>/dev/null; then
    echo "Błąd: python3 nie jest zainstalowany." >&2
    echo "Zainstaluj: sudo apt install python3  lub  sudo dnf install python3" >&2
    exit 1
fi
echo "  ✔ python3: $(python3 --version)"

if ! command -v xdg-open &>/dev/null; then
    echo "Ostrzeżenie: xdg-open nie znaleziony (pakiet xdg-utils)" >&2
    echo "  Zainstaluj: sudo apt install xdg-utils" >&2
fi

if ! command -v xdg-mime &>/dev/null; then
    echo "Ostrzeżenie: xdg-mime nie znaleziony — rejestracja MIME nie będzie możliwa" >&2
fi

# ── Instalacja skryptu CLI ──
echo "▶ Instalacja skryptu CLI → $BIN_DEST"
sudo cp "$SCRIPT_SRC" "$BIN_DEST"
sudo chmod +x "$BIN_DEST"
echo "  ✔ Skrypt zainstalowany"

# ── Instalacja szablonu HTML ──
echo "▶ Instalacja szablonu HTML → $TEMPLATE_DEST"
sudo mkdir -p "$(dirname "$TEMPLATE_DEST")"
sudo cp "$TEMPLATE_SRC" "$TEMPLATE_DEST"
sudo chmod 644 "$TEMPLATE_DEST"
echo "  ✔ Szablon zainstalowany"

# ── Tworzenie pliku .desktop ──
echo "▶ Tworzenie pliku .desktop → $DESKTOP_FILE"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_FILE" << DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Wizualizator EML
GenericName=Podgląd wiadomości EML
Comment=Otwiera plik .eml jako lokalny podgląd HTML
Exec=$BIN_DEST %f
Icon=internet-mail
Terminal=false
MimeType=message/rfc822;application/vnd.ms-outlook;
Categories=Network;Email;
StartupNotify=false
DESKTOP
chmod 644 "$DESKTOP_FILE"
echo "  ✔ Plik .desktop utworzony"

# ── Rejestracja MIME type dla .msg ──
MIME_DIR="$HOME/.local/share/mime/packages"
MIME_FILE="$MIME_DIR/eml-gmail-msg.xml"
mkdir -p "$MIME_DIR"
cat > "$MIME_FILE" << 'MIMEXML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/vnd.ms-outlook">
    <comment>Wiadomość Microsoft Outlook</comment>
    <glob pattern="*.msg"/>
    <magic priority="60">
      <match type="string" offset="0" value="\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"/>
    </magic>
  </mime-type>
</mime-info>
MIMEXML
if command -v update-mime-database &>/dev/null; then
    update-mime-database "$HOME/.local/share/mime"
    echo "  ✔ MIME type application/vnd.ms-outlook zarejestrowany"
else
    echo "  ⚠ update-mime-database niedostępny — pomiń rejestrację MIME"
fi

# ── Aktualizacja bazy .desktop ──
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR"
    echo "  ✔ Baza aplikacji zaktualizowana"
fi

# ── Rejestracja jako domyślna aplikacja ──
if command -v xdg-mime &>/dev/null; then
    xdg-mime default eml-gmail.desktop message/rfc822
    xdg-mime default eml-gmail.desktop application/vnd.ms-outlook
    echo "  ✔ Ustawiono jako domyślną aplikację dla message/rfc822 i application/vnd.ms-outlook"

    # Weryfikacja
    DEFAULT=$(xdg-mime query default message/rfc822 2>/dev/null || echo "nieznana")
    echo "  ✔ Weryfikacja: domyślna aplikacja dla .eml = $DEFAULT"
else
    echo ""
    echo "  ⚠  xdg-mime niedostępny — ustaw domyślną aplikację ręcznie:"
    echo "     Menedżer plików → PPM na plik .eml/.msg → Otwórz za pomocą"
    echo "     → Wizualizator EML → Ustaw jako domyślną"
fi

echo ""
echo "✔ Instalacja zakończona!"
echo "  CLI:      $BIN_DEST"
echo "  Szablon:  $TEMPLATE_DEST"
echo "  Desktop:  $DESKTOP_FILE"
echo ""
echo "  Test terminala: eml-gmail ~/jakis-plik.eml"
echo "  Test dwukliku:  xdg-open ~/jakis-plik.eml"
