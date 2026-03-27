#Requires -Version 5.1
#Requires -RunAsAdministrator
# uninstall-windows-admin.ps1 - odinstalowuje Wizualizator EML
# Usuwa wszystkie zmiany wprowadzone przez setup-windows-admin.ps1
#
# Wywolywany automatycznie przez uninstall-launcher.bat z Dodaj/Usun Programy,
# lub recznie: Set-ExecutionPolicy -Scope Process Bypass; .\uninstall-windows-admin.ps1

$ErrorActionPreference = "Stop"

$INSTALL_DIR  = "$env:ProgramFiles\eml-gmail"
$PROG_ID      = "EML.Viewer"
$regBase      = "HKLM:\Software\Classes"
$arpKey       = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WizualizatorEML"

Write-Host "=== Dezinstalacja Wizualizatora EML ===" -ForegroundColor Cyan
Write-Host ""

# Usuwamy wpis ARP jako pierwszy - jesli cos sie posypie pozniej,
# kolejne uruchomienie nie bedzie juz widoczne w panelu
Write-Host "Usuwanie wpisu z Dodaj/Usun Programy..."
if (Test-Path $arpKey) {
    Remove-Item -Recurse -Force -Path $arpKey
    Write-Host "  OK Usunieto wpis z Dodaj/Usun Programy" -ForegroundColor Green
} else {
    Write-Host "  INFO Brak wpisu w ARP, pomijam"
}

# -- Usuniecie skojarzen plikow (.eml, .msg) --
Write-Host "Usuwanie skojarzen plikow w HKLM..."
foreach ($ext in @(".eml", ".msg")) {
    $extPath = "$regBase\$ext"
    if (Test-Path $extPath) {
        $defVal = (Get-ItemProperty -Path $extPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
        if ($defVal -eq $PROG_ID) {
            Remove-ItemProperty -Path $extPath -Name "(Default)" -ErrorAction SilentlyContinue
        }
        $owpPath = "$extPath\OpenWithProgids"
        if (Test-Path $owpPath) {
            Remove-ItemProperty -Path $owpPath -Name $PROG_ID -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "  OK Usunieto skojarzenia .eml i .msg" -ForegroundColor Green

# -- Usuniecie ProgID EML.Viewer --
$progIdPath = "$regBase\$PROG_ID"
if (Test-Path $progIdPath) {
    Remove-Item -Recurse -Force -Path $progIdPath
    Write-Host "  OK Usunieto ProgID $PROG_ID" -ForegroundColor Green
} else {
    Write-Host "  INFO ProgID $PROG_ID nie istnieje, pomijam"
}

# -- Usuniecie z RegisteredApplications --
$regAppPath = "HKLM:\Software\RegisteredApplications"
if ((Get-ItemProperty -Path $regAppPath -Name "WizualizatorEML" -ErrorAction SilentlyContinue) -ne $null) {
    Remove-ItemProperty -Path $regAppPath -Name "WizualizatorEML" -ErrorAction SilentlyContinue
    Write-Host "  OK Usunieto WizualizatorEML z RegisteredApplications" -ForegroundColor Green
} else {
    Write-Host "  INFO Brak wpisu w RegisteredApplications, pomijam"
}

# -- Usuniecie z PATH systemowego --
Write-Host "Usuwanie z systemowego PATH..."
$sysPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
if ($sysPath -like "*$INSTALL_DIR*") {
    $newPath = ($sysPath -split ";" | Where-Object { $_.Trim() -ne $INSTALL_DIR.Trim() }) -join ";"
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::Machine)
    Write-Host "  OK Usunieto $INSTALL_DIR z PATH" -ForegroundColor Green
} else {
    Write-Host "  INFO Brak wpisu w PATH, pomijam"
}

# -- Powiadomienie Explorera (przed usunieciem plikow) --
Add-Type -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, uint f, IntPtr a, IntPtr b);' -Name WinAPI -Namespace Shell32 -ErrorAction SilentlyContinue
[Shell32.WinAPI]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
Write-Host "  OK Explorer powiadomiony o zmianie skojarzen" -ForegroundColor Green

# -- Usuniecie plikow (na samym koncu - skrypt sam siebie usuwa) --
Write-Host "Usuwanie plikow z $INSTALL_DIR ..."
if (Test-Path $INSTALL_DIR) {
    Start-Sleep -Milliseconds 500
    Remove-Item -Recurse -Force -Path $INSTALL_DIR -ErrorAction SilentlyContinue
    if (Test-Path $INSTALL_DIR) {
        Write-Warning "  UWAGA: Nie udalo sie usunac $INSTALL_DIR - usun recznie"
    } else {
        Write-Host "  OK Usunieto katalog $INSTALL_DIR" -ForegroundColor Green
    }
} else {
    Write-Host "  INFO Katalog nie istnieje, pomijam"
}

Write-Host ""
Write-Host "Dezinstalacja zakonczona pomyslnie!" -ForegroundColor Cyan
Write-Host "Mozesz zamknac to okno."
Start-Sleep -Seconds 3
