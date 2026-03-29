#!/usr/bin/env bash
# eml-gmail — otwiera plik .eml / .msg jako lokalny self-contained HTML (bez serwera)
#
# Instalacja:
#   sudo cp eml-gmail.sh /usr/local/bin/eml-gmail
#   sudo chmod +x /usr/local/bin/eml-gmail
#   sudo mkdir -p /usr/local/share/eml-gmail
#   sudo cp EML-Gmail.html /usr/local/share/eml-gmail/index.html
#
# Użycie:
#   eml-gmail /ścieżka/do/wiadomość.eml
#   eml-gmail /ścieżka/do/wiadomość.msg

set -euo pipefail

TEMPLATE="/usr/local/share/eml-gmail/index.html"

# ── Sprawdzenie argumentów ──
if [[ $# -lt 1 ]]; then
    echo "Użycie: eml-gmail <plik.eml>" >&2
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "Błąd: plik nie istnieje: $FILE" >&2
    exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Błąd: brak szablonu: $TEMPLATE" >&2
    echo "Zainstaluj: sudo cp EML-Gmail.html $TEMPLATE" >&2
    exit 1
fi


# ── Sprawdzenie rozmiaru (limit 30 MB) ──
MAX_BYTES=$((30 * 1024 * 1024))
FILE_BYTES=$(wc -c < "$FILE")
if (( FILE_BYTES > MAX_BYTES )); then
    echo "Błąd: plik za duży ($(( FILE_BYTES / 1024 / 1024 )) MB). Limit: 30 MB." >&2
    exit 1
fi

# ── Sprawdzenie python3 ──
if ! command -v python3 &>/dev/null; then
    echo "Błąd: python3 nie jest zainstalowany." >&2
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "Zainstaluj: xcode-select --install  lub  brew install python3" >&2
    else
        echo "Zainstaluj: sudo apt install python3  lub  sudo dnf install python3" >&2
    fi
    exit 1
fi

# ── Tworzenie tymczasowego pliku HTML z wbudowanymi danymi EML ──
# Python obsługuje duże pliki bez ograniczeń powłoki (ARG_MAX)
# mktemp: na macOS nie obsługuje suffixu w ścieżce — używamy -t + mv
if [[ "$(uname)" == "Darwin" ]]; then
    TMPFILE=$(mktemp -t eml-gmail)
    mv "$TMPFILE" "${TMPFILE}.html"
    TMPFILE="${TMPFILE}.html"
else
    TMPFILE=$(mktemp /tmp/eml-gmail-XXXXXX.html)
fi

python3 - "$FILE" "$TEMPLATE" "$TMPFILE" << 'PYEOF'
import sys, base64, os, json

eml_path      = sys.argv[1]
template_path = sys.argv[2]
output_path   = sys.argv[3]

MAX_BYTES = 30 * 1024 * 1024
with open(eml_path, 'rb') as f:
    raw = f.read(MAX_BYTES + 1)
if len(raw) > MAX_BYTES:
    sys.exit("Błąd: plik przekracza limit 30 MB")

b64      = base64.b64encode(raw).decode('ascii')
# json.dumps zapewnia bezpieczne escapowanie: \, ", \n, </script itp.
filename = json.dumps(os.path.basename(eml_path))

with open(template_path, 'r', encoding='utf-8') as f:
    html = f.read()

inject = (
    f'<script>'
    f'window.EMBEDDED_EML={json.dumps(b64)};'
    f'window.EMBEDDED_EML_NAME={filename};'
    f'</script>'
)
html = html.replace('</head>', inject + '\n</head>', 1)

with open(output_path, 'w', encoding='utf-8') as f:
    f.write(html)

size_kb = len(raw) // 1024
print(f"Wygenerowano: {output_path}  ({size_kb} KB)")
PYEOF

# Poczekaj aż przeglądarka wczyta plik, potem usuń
# 10 sekund dla pewności przy dużych plikach lub wolnych maszynach
sleep 10 && rm -f "$TMPFILE" &
disown $!

# ── Otwarcie przeglądarki ──
if command -v xdg-open &>/dev/null; then
    xdg-open "$TMPFILE"
elif command -v open &>/dev/null; then      # macOS
    open "$TMPFILE"
elif command -v wslview &>/dev/null; then   # WSL
    wslview "$TMPFILE"
elif [[ -n "${BROWSER:-}" ]]; then
    "$BROWSER" "$TMPFILE"
else
    echo "Nie znaleziono przeglądarki. Otwórz ręcznie: $TMPFILE" >&2
fi
