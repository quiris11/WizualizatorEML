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

---

## Odpowiadanie na wiadomość przez Gmail

Wizualizator umożliwia wygodne odpowiadanie na wczytaną wiadomość przez Gmail:

1. **Skopiuj cytowaną treść** — kliknij przycisk `📋 Skopiuj cytowanie`, który kopiuje oryginalną wiadomość do schowka z zachowanym formatowaniem HTML (pogrubienia, kursywy, linki, tabele)
2. **Otwórz szkic odpowiedzi** — kliknij przycisk `✉️ Otwórz szkic odpowiedzi w Gmail`, który otwiera Gmail w nowej karcie z automatycznie uzupełnionym:
   - adresatem (`Do:`) — adres nadawcy oryginalnej wiadomości
   - tematem (`Re: ...`) — temat oryginalnej wiadomości z prefiksem `Re:`
3. **Wklej cytowanie** — w oknie Gmaila wklej treść ze schowka skrótem `Ctrl+V` (Windows/Linux) lub `Cmd+V` (macOS)
4. Napisz odpowiedź i wyślij

> **Wskazówka:** wiadomości w formacie HTML zachowują pełne formatowanie przy wklejaniu w Gmail. Wiadomości tekstowe są wklejane jako zwykły tekst z cytowaniem oznaczonym `>`.

---

**Na Linuksie** — instalator rejestruje plik `.desktop` jako domyślną aplikację
dla typu MIME `message/rfc822`, który obejmuje pliki `.eml`.

**Na macOS** — instalator tworzy aplikację `.app` skompilowaną z AppleScript,
która odbiera zdarzenia otwarcia pliku (`on open`) i przekazuje ścieżkę do skryptu.

**Na Windows** — instalator rejestruje skojarzenie `.eml` w rejestrze systemowym
(`HKCU\Software\Classes`) i wywołuje skrypt PowerShell przy każdym otwarciu pliku.

---

## Użycie bez instalacji — bezpośrednio w przeglądarce

Plik `EML-Gmail.html` można używać **samodzielnie, bez instalacji**. Wystarczy otworzyć go w przeglądarce i wczytać plik `.eml` ręcznie:

1. Otwórz `EML-Gmail.html` w przeglądarce (dwuklik lub `Plik → Otwórz`)
2. Przeciągnij plik `.eml` na strefę upuszczania **lub** kliknij `Wybierz plik .eml`
3. Wizualizator wyświetli treść wiadomości

Jest to przydatne gdy:
- chcesz podejrzeć pojedynczy plik bez instalowania czegokolwiek
- używasz komputera bez uprawnień administratora (`sudo`)

> **Uwaga:** w tym trybie dwuklik na plik `.eml` w menedżerze plików nie działa automatycznie — plik `.eml` trzeba wczytać ręcznie przez interfejs strony. Automatyczny dwuklik wymaga instalacji przez `setup-linux.sh`, `setup-macos.sh` lub `setup-windows.ps1`.

---

## ⚠️ Przed instalacją

Wszystkie cztery pliki muszą znajdować się w **tym samym katalogu**:

```
EML-Gmail-v11.html   ← szablon podglądu (wymagany)
eml-gmail.sh         ← skrypt CLI Linux/macOS (wymagany)
eml-gmail.ps1        ← skrypt CLI Windows (wymagany)
setup-linux.sh       ← instalator Linux
setup-macos.sh       ← instalator macOS
setup-windows.ps1    ← instalator Windows
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

## Wymagania — Windows

| Zależność | Uwagi |
|---|---|
| Windows 10 / 11 | PowerShell 5.1 wbudowany |
| PowerShell 5.1+ | wbudowany — bez instalacji |
| Python 3 | **niewymagany** — skrypt używa wbudowanego Base64 PowerShell |

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

## Instalacja — Windows (10 / 11)

```powershell
# Uruchom PowerShell w katalogu z plikami, następnie:
Set-ExecutionPolicy -Scope Process Bypass
.\setup-windows.ps1
```

Instalator automatycznie:
- Kopiuje skrypt CLI → `%LOCALAPPDATA%\eml-gmail\eml-gmail.ps1`
- Kopiuje szablon HTML → `%LOCALAPPDATA%\eml-gmail\index.html`
- Tworzy wrapper `eml-gmail.bat` — wywołanie z CMD/PowerShell jako `eml-gmail`
- Dodaje katalog instalacji do `PATH` użytkownika
- Rejestruje skojarzenie `.eml` w rejestrze (`HKCU`) — **bez uprawnień admina**
- Powiadamia Eksploratora Windows o zmianie skojarzeń

**Test po instalacji** (w nowym oknie PowerShell/CMD):
```cmd
eml-gmail C:\Users\user\Pobrane\wiadomosc.eml
```

> **Uwaga:** po instalacji uruchom **nowe** okno PowerShell lub CMD,
> żeby zaktualizowany `PATH` zaczął obowiązywać.

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
         ├─ Python/PowerShell: czyta .eml → koduje Base64
         ├─ Python/PowerShell: wstrzykuje dane do szablonu HTML
         ├─ Zapisuje plik tymczasowy HTML
         └─ Otwiera przeglądarkę (xdg-open / open / Start-Process)
              └─ JavaScript parsuje EML lokalnie
                   ├─ Nagłówki: From / To / Subject / Date
                   ├─ Dekoduje quoted-printable i base64
                   ├─ Obsługuje charset: UTF-8, ISO-8859-2, Windows-1250…
                   ├─ Podmienia obrazy inline (cid:) na data: URI
                   ├─ Renderuje HTML maila w Shadow DOM (izolacja CSS)
                   └─ Załączniki: lista z możliwością pobrania
```

Plik tymczasowy jest automatycznie usuwany po 2 sekundach od otwarcia w przeglądarce.
