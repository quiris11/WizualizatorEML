# Wizualizator EML

Lokalny podgląd plików `.eml` działający w przeglądarce internetowej.
Wszystkie dane pozostają na komputerze — żaden plik nie jest wysyłany do sieci.

---

## Co to robi i jak to działa

Wizualizator EML pozwala otwierać pliki `.eml` **dwuklikiem z menedżera plików**
i wyświetla ich treść w **domyślnej przeglądarce internetowej**.

Kolejność działania po dwukliku:

1. System operacyjny kojarzy rozszerzenie `.eml` z aplikacją **Wizualizator EML**
2. System przekazuje ścieżkę klikniętego pliku do skryptu `eml-gmail`
3. Skrypt wczytuje plik `.eml` i osadza jego zawartość w tymczasowym pliku HTML
4. Plik HTML otwiera się w domyślnej przeglądarce
5. JavaScript parsuje wiadomość lokalnie i wyświetla:
   - nadawcę, odbiorcę, temat
   - treść wiadomości (HTML lub tekst)
   - załączniki z możliwością pobrania

**Na Linuksie** — instalator rejestruje plik `.desktop` jako domyślną aplikację
dla typu MIME `message/rfc822`, który obejmuje pliki `.eml`.

**Na macOS** — instalator tworzy aplikację `.app` skompilowaną z AppleScript,
która odbiera zdarzenia otwarcia pliku (`on open`) i przekazuje ścieżkę do skryptu.

---

## ⚠️ Przed instalacją

Wszystkie cztery pliki muszą znajdować się w **tym samym katalogu**:

```
EML-Gmail.html   ← szablon podglądu (wymagany)
eml-gmail.sh         ← skrypt CLI (wymagany)
setup-linux.sh       ← instalator Linux
setup-macos.sh       ← instalator macOS
```

---

## Wymagania — Linux

| Zależność | Debian / Ubuntu / Zorin OS | Fedora / RHEL / CentOS |
|---|---|---|
| Python 3 | `sudo apt install python3` | `sudo dnf install python3` |
| xdg-utils | `sudo apt install xdg-utils` | `sudo dnf install xdg-utils` |
| desktop-file-utils | `sudo apt install desktop-file-utils` | `sudo dnf install desktop-file-utils` |

## Wymagania — macOS

| Zależność | Instalacja |
|---|---|
| Python 3 + osacompile | `xcode-select --install` |
| duti *(opcjonalne, do ustawienia domyślnej aplikacji z CLI)* | `brew install duti` |

---

## Instalacja — Linux

```bash
chmod +x setup-linux.sh
./setup-linux.sh
```

Instalator automatycznie:
- Kopiuje skrypt CLI → `/usr/local/bin/eml-gmail`
- Kopiuje szablon HTML → `/usr/local/share/eml-gmail/index.html`
- Tworzy plik `.desktop` → `~/.local/share/applications/eml-gmail.desktop`
- Rejestruje aplikację jako domyślną dla `.eml` przez `xdg-mime`

**Test po instalacji:**
```bash
eml-gmail ~/wiadomosc.eml     # uruchomienie z terminala
xdg-open ~/wiadomosc.eml      # symulacja dwukliku
```

> **Fedora / GNOME:** jeśli po instalacji dwuklik nadal otwiera inną aplikację:
> ```bash
> gio mime message/rfc822 eml-gmail.desktop
> ```

---

## Instalacja — macOS (Ventura / Sonoma / Tahoe)

```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

Instalator automatycznie:
- Kopiuje skrypt CLI → `/usr/local/bin/eml-gmail`
- Kopiuje szablon HTML → `/usr/local/share/eml-gmail/index.html`
- Kompiluje aplikację AppleScript → `~/Applications/Wizualizator EML.app`
- Usuwa atrybut kwarantanny (`xattr -cr`)
- Podpisuje aplikację ad-hoc (`codesign --sign -`)
- Rejestruje w Launch Services

**Ustawienie domyślnej aplikacji:**
```bash
# Przez duti (zalecane):
brew install duti
duti -s local.eml-gmail .eml all

# Lub ręcznie w Finderze:
# PPM na plik .eml → Otwórz za pomocą → Inna aplikacja
# → Wizualizator EML → Zawsze otwieraj
```

**Test po instalacji:**
```bash
eml-gmail ~/wiadomosc.eml                        # uruchomienie z terminala
open -a "Wizualizator EML" ~/wiadomosc.eml       # symulacja dwukliku
```

---

## Użycie z terminala

```bash
# Pełna ścieżka
eml-gmail /home/user/Pobrane/faktura.eml

# Plik w bieżącym katalogu
eml-gmail "Odpowiedź od ZUS.eml"

# Najnowszy plik .eml w katalogu
eml-gmail "$(ls -t ~/mail/*.eml | head -1)"
```

---

## Jak to działa (szczegóły techniczne)

```
Dwuklik .eml
    └─ eml-gmail.sh
         ├─ Python: czyta .eml → koduje base64
         ├─ Python: wstrzykuje dane do szablonu HTML
         ├─ Zapisuje /tmp/eml-gmail-PID.html
         └─ Otwiera przeglądarkę (xdg-open / open)
              └─ JavaScript parsuje EML lokalnie
                   ├─ Nagłówki: From / To / Subject / Date
                   ├─ Dekoduje quoted-printable i base64
                   ├─ Obsługuje charset: UTF-8, ISO-8859-2, Windows-1250…
                   ├─ Podmienia obrazy inline (cid:) na data: URI
                   ├─ Renderuje HTML maila w Shadow DOM (izolacja CSS)
                   └─ Załączniki: lista z możliwością pobrania
```

Plik tymczasowy jest automatycznie usuwany po 2 sekundach od otwarcia w przeglądarce.
