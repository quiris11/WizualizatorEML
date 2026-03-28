# Wizualizator EML

Lokalny podgląd plików `.eml` oraz `.msg` działający w przeglądarce internetowej.
Wszystkie dane pozostają na komputerze — żaden plik nie jest wysyłany do sieci.

***

## Co to robi i jak to działa

Wizualizator EML pozwala otwierać pliki `.eml` oraz `.msg` **dwuklikiem z menedżera plików**
i wyświetla ich treść w **domyślnej przeglądarce internetowej**.

Kolejność działania po dwukliku:

1. System operacyjny kojarzy rozszerzenie `.eml` oraz `.msg` z aplikacją **Wizualizator EML**
2. System przekazuje ścieżkę klikniętego pliku do skryptu `eml-gmail`
3. Skrypt wczytuje plik `.eml` lub `.msg` i osadza jego zawartość w tymczasowym pliku HTML
4. Plik HTML otwiera się w domyślnej przeglądarce
5. JavaScript parsuje wiadomość lokalnie i wyświetla:
    - nadawcę, odbiorcę, temat
    - treść wiadomości (HTML lub tekst)
    - załączniki z możliwością pobrania

**Na Linuksie** — instalator rejestruje plik `.desktop` jako domyślną aplikację do otwierania `.eml`oraz `.msg` 

**Na macOS** — instalator tworzy aplikację `.app` skompilowaną z AppleScript,
która odbiera zdarzenia otwarcia pliku (`on open`) i przekazuje ścieżkę do skryptu.

**Na Windows** — instalator rejestruje aplikację w rejestrze systemowym
(`HKLM\Software\Classes`) dla wszystkich użytkowników i wywołuje skrypt PowerShell przy każdym otwarciu pliku. Skojarzenie domyślne ustawiane jest przez GPO.

***

## Odpowiadanie na wiadomość przez Gmail

Wizualizator umożliwia wygodne odpowiadanie na wczytaną wiadomość przez Gmail:

1. **Skopiuj cytowaną treść** — kliknij przycisk `📋 Skopiuj cytowanie`, który kopiuje oryginalną wiadomość do schowka z zachowanym formatowaniem HTML (pogrubienia, kursywy, linki, tabele)
2. **Otwórz szkic odpowiedzi** — kliknij przycisk `✉️ Otwórz szkic odpowiedzi w Gmail`, który otwiera Gmail w nowej karcie z automatycznie uzupełnionym:
    - adresatem (`Do:`) — adres nadawcy oryginalnej wiadomości
    - tematem (`Re: ...`) — temat oryginalnej wiadomości z prefiksem `Re:`
3. **Wklej cytowanie** — w oknie Gmaila wklej treść ze schowka skrótem `Ctrl+V` (Windows/Linux) lub `Cmd+V` (macOS)
4. Napisz odpowiedź i wyślij

> **Wskazówka:** wiadomości w formacie HTML zachowują pełne formatowanie przy wklejaniu w Gmail. Wiadomości tekstowe są wklejane jako zwykły tekst z cytowaniem oznaczonym `>`.

***

## Użycie bez instalacji — bezpośrednio w przeglądarce

Plik `EML-Gmail.html` można używać **samodzielnie, bez instalacji**. Wystarczy otworzyć go w przeglądarce i wczytać plik `.eml` lub `.msg` ręcznie:

1. Otwórz `EML-Gmail.html` w przeglądarce (dwuklik lub `Plik → Otwórz`)
2. Przeciągnij plik `.eml` lub `.msg` na strefę upuszczania **lub** kliknij `Wybierz plik .eml`
3. Wizualizator wyświetli treść wiadomości

Jest to przydatne gdy:

- chcesz podejrzeć pojedynczy plik bez instalowania czegokolwiek
- używasz komputera bez uprawnień administratora (`sudo`)
- chcesz udostępnić plik znajomemu — wystarczy wysłać sam `EML-Gmail.html`

> **Uwaga:** w tym trybie dwuklik na plik `.eml` lub `.msg` w menedżerze plików nie działa automatycznie — plik trzeba wczytać ręcznie przez interfejs strony. Automatyczny dwuklik wymaga instalacji przez `setup-linux.sh`, `setup-macos.sh` lub `setup-windows-admin.ps1`.

***

## ⚠️ Przed instalacją

Wszystkie pliki muszą znajdować się w **tym samym katalogu**:

```
EML-Gmail.html              ← szablon podglądu (wymagany)
eml-gmail.sh                ← skrypt CLI Linux/macOS (wymagany)
eml-gmail.ps1               ← skrypt CLI Windows (wymagany)
setup-linux.sh              ← instalator Linux
setup-macos.sh              ← instalator macOS
setup-windows-admin.ps1     ← instalator Windows (wymaga uprawnień admina)
uninstall-windows-admin.ps1 ← dezinstalator Windows
```


***

## Wymagania — Linux

| Zależność | Debian / Ubuntu / Zorin OS | Fedora / RHEL / CentOS |
| :-- | :-- | :-- |
| Python 3 | `sudo apt install python3` | `sudo dnf install python3` |
| xdg-utils | `sudo apt install xdg-utils` | `sudo dnf install xdg-utils` |
| desktop-file-utils | `sudo apt install desktop-file-utils` | `sudo dnf install desktop-file-utils` |

## Wymagania — macOS

| Zależność | Instalacja |
| :-- | :-- |
| Python 3 + osacompile | `xcode-select --install` |
| duti *(opcjonalne, do ustawienia domyślnej aplikacji z CLI)* | `brew install duti` |

## Wymagania — Windows

| Zależność | Uwagi |
| :-- | :-- |
| Windows 10 / 11 | PowerShell 5.1 wbudowany |
| PowerShell 5.1+ | wbudowany — bez instalacji |
| Uprawnienia administratora | wymagane przez `setup-windows-admin.ps1` |
| Python 3 | **niewymagany** — skrypt używa wbudowanego Base64 PowerShell |


***

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
> ```bash > gio mime message/rfc822 eml-gmail.desktop > ```

***

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


***

## Instalacja — Windows (10 / 11)

Instalator `setup-windows-admin.ps1` wymaga uprawnień administratora i instaluje aplikację dla **wszystkich użytkowników** na komputerze.

```cmd
:: Uruchom CMD jako Administrator, następnie:
powershell.exe -ExecutionPolicy Bypass -File setup-windows-admin.ps1
```

Instalator automatycznie:

- Kopiuje skrypt CLI → `%ProgramFiles%\eml-gmail\eml-gmail.ps1`
- Kopiuje szablon HTML → `%ProgramFiles%\eml-gmail\index.html`
- Kopiuje dezinstalator → `%ProgramFiles%\eml-gmail\uninstall.ps1`
- Tworzy wrapper `eml-gmail.bat` — wywołanie z CMD/PowerShell jako `eml-gmail`
- Dodaje katalog instalacji do systemowego `PATH` (`HKLM`)
- Rejestruje ProgID `EML.Viewer` w rejestrze systemowym (`HKLM\Software\Classes`)
- Dodaje aplikację do `OpenWithProgids` dla `.eml` i `.msg` — **bez nadpisywania domyślnego handlera**
- Rejestruje aplikację w Dodaj/Usuń Programy
- Powiadamia Eksploratora Windows o zmianie skojarzeń

**Test po instalacji** (w nowym oknie CMD):

```cmd
eml-gmail C:\Users\user\Pobrane\wiadomosc.eml
```

### Ustawienie domyślnej aplikacji przez GPO

Instalator celowo **nie nadpisuje** domyślnego handlera `.eml`/`.msg` — zapobiega to uruchamianiu naprawy przez Office 2016/2019. Skojarzenie domyślne ustawia się przez GPO przy użyciu pliku XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
    <Association Identifier=".eml" ProgId="EML.Viewer" ApplicationName="Wizualizator EML" />
    <Association Identifier=".msg" ProgId="EML.Viewer" ApplicationName="Wizualizator EML" />
</DefaultAssociations>
```

Polityka: *Konfiguracja komputera → Szablony administracyjne → Składniki systemu Windows → Eksplorator plików → Ustaw plik konfiguracji domyślnych skojarzeń aplikacji*

Skojarzenia są stosowane przy **logowaniu użytkownika** po `gpupdate /force`.

***

## Użycie z terminala

```bash
# Linux / macOS
eml-gmail /home/user/Pobrane/faktura.eml
eml-gmail "Odpowiedz od ZUS.eml"
```

```cmd
:: Windows
eml-gmail C:\Users\user\Pobrane\faktura.eml
eml-gmail "Odpowiedz od ZUS.eml"
```


***

## Jak to działa (szczegóły techniczne)

```
Dwuklik .eml
    └─ eml-gmail.sh / eml-gmail.ps1
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

