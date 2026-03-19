#Requires -Version 5.1
# setup-windows.ps1 - instaluje Wizualizator EML na Windows
#
# Uzycie (uruchom w PowerShell):
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\setup-windows.ps1

$ErrorActionPreference = "Stop"

$SCRIPT_SRC   = ".\eml-gmail.ps1"
$TEMPLATE_SRC = ".\EML-Gmail.html"
$INSTALL_DIR  = "$env:LOCALAPPDATA\eml-gmail"
$TEMPLATE_DST = "$INSTALL_DIR\index.html"
$SCRIPT_DST   = "$INSTALL_DIR\eml-gmail.ps1"
$BAT_DST      = "$INSTALL_DIR\eml-gmail.bat"

# -- Sprawdzenie plikow zrodlowych --
if (-not (Test-Path $SCRIPT_SRC))   { Write-Error "Blad: brak $SCRIPT_SRC";   exit 1 }
if (-not (Test-Path $TEMPLATE_SRC)) { Write-Error "Blad: brak $TEMPLATE_SRC"; exit 1 }

# -- Instalacja plikow --
Write-Host "Instalacja plikow -> $INSTALL_DIR"
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
Copy-Item $TEMPLATE_SRC $TEMPLATE_DST -Force
Copy-Item $SCRIPT_SRC   $SCRIPT_DST   -Force
Write-Host "  OK Szablon HTML zainstalowany"
Write-Host "  OK Skrypt PowerShell zainstalowany"

# -- Wrapper .bat --
$psExe = (Get-Command powershell.exe).Source
$batContent = "@echo off`r`n`"$psExe`" -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SCRIPT_DST`" %*`r`n"
[System.IO.File]::WriteAllText($BAT_DST, $batContent, [System.Text.Encoding]::ASCII)
Write-Host "  OK Wrapper eml-gmail.bat zainstalowany"

# -- Dodanie do PATH uzytkownika --
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($userPath -notlike "*$INSTALL_DIR*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$INSTALL_DIR", [System.EnvironmentVariableTarget]::User)
    Write-Host "  OK Dodano $INSTALL_DIR do PATH"
} else {
    Write-Host "  OK PATH juz zawiera katalog instalacji"
}

# -- Rejestracja skojarzenia .eml (HKCU - bez admina) --
Write-Host "Rejestracja skojarzenia .eml..."
$openCmd = "`"$psExe`" -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SCRIPT_DST`" `"%1`""
$regBase = "HKCU:\Software\Classes"

New-Item -Force -Path "$regBase\.eml"                           | Out-Null
Set-ItemProperty -Path "$regBase\.eml" -Name "(Default)"         -Value "EML.Viewer"
New-Item -Force -Path "$regBase\EML.Viewer"                     | Out-Null
Set-ItemProperty -Path "$regBase\EML.Viewer" -Name "(Default)"   -Value "Wizualizator EML"
New-Item -Force -Path "$regBase\EML.Viewer\shell\open\command" | Out-Null
Set-ItemProperty -Path "$regBase\EML.Viewer\shell\open\command" -Name "(Default)" -Value $openCmd

# Rejestracja w OpenWithProgids - aplikacja jest widoczna na liscie "Otworz za pomoca"
New-Item -Force -Path "$regBase\.eml\OpenWithProgids" | Out-Null
Set-ItemProperty -Path "$regBase\.eml\OpenWithProgids" -Name "EML.Viewer" -Value "" -Type String
New-Item -Force -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.eml\OpenWithProgids" | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.eml\OpenWithProgids" -Name "EML.Viewer" -Value "" -Type String
Write-Host "  OK Skojarzenie .eml -> Wizualizator EML zarejestrowane"

# -- Powiadomienie Explorera --
Add-Type -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, uint f, IntPtr a, IntPtr b);' -Name WinAPI -Namespace Shell32 -ErrorAction SilentlyContinue
[Shell32.WinAPI]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
Write-Host "  OK Explorer powiadomiony o zmianie skojarzen"

Write-Host ""
Write-Host "Instalacja zakonczona!"
Write-Host "  Skrypt  : $SCRIPT_DST"
Write-Host "  Szablon : $TEMPLATE_DST"
Write-Host ""
Write-Host "UWAGA: Uruchom nowe okno PowerShell/CMD - PATH zostal zaktualizowany."
Write-Host ""
# -- Windows 11 nie pozwala skryptom ustawiac domyslnej aplikacji --
# -- Uzytkownik musi to zrobic recznie (jeden klik) --
Write-Host "--- Ustawianie domyslnej aplikacji dla .eml ---"
Write-Host "Windows 11 wymaga recznego ustawienia. Wykonaj jeden z ponizszych krokow:"
Write-Host ""
Write-Host "  Sposob 1 (najszybszy - prawy klik na plik .eml):"
Write-Host "    Otworz za pomoca -> Wybierz inna aplikacje"
Write-Host "    Zaznacz: Wizualizator EML"
Write-Host "    Zaznacz: Zawsze uzywaj tej aplikacji -> OK"
Write-Host ""
Write-Host "  Sposob 2 (przez Ustawienia):"
Write-Host "    Ustawienia -> Aplikacje -> Domyslne aplikacje -> wyszukaj: .eml"
Write-Host "    Wybierz: Wizualizator EML"
Write-Host ""
$answer = Read-Host "Otworzyc Ustawienia -> Domyslne aplikacje teraz? (t/n)"
if ($answer -eq "t" -or $answer -eq "T") {
    Start-Process "ms-settings:defaultapps"
    Write-Host "Wyszukaj .eml i wybierz Wizualizator EML."
}
