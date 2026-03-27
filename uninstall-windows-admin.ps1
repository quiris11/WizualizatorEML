#Requires -Version 5.1
#Requires -RunAsAdministrator
# uninstall-windows-admin.ps1 - odinstalowuje Wizualizator EML
# Usuwa wszystkie zmiany wprowadzone przez setup-windows-admin.ps1
#
# Uzycie (PowerShell jako Administrator):
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\uninstall-windows-admin.ps1

$ErrorActionPreference = "Stop"

$INSTALL_DIR  = "$env:ProgramFiles\eml-gmail"
$PROG_ID      = "EML.Viewer"
$regBase      = "HKLM:\Software\Classes"
$arpKey       = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WizualizatorEML"

Write-Host "=== Dezinstalacja Wizualizatora EML ==="
Write-Host ""

# -- Usuniecie plikow --
Write-Host "Usuwanie plikow z $INSTALL_DIR ..."
if (Test-Path $INSTALL_DIR) {
    Remove-Item -Recurse -Force -Path $INSTALL_DIR
    Write-Host "  OK Usunieto katalog $INSTALL_DIR"
} else {
    Write-Host "  INFO Katalog nie istnieje, pomijam"
}

# -- Usuniecie z PATH systemowego --
Write-Host "Usuwanie z systemowego PATH..."
$sysPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
if ($sysPath -like "*$INSTALL_DIR*") {
    $newPath = ($sysPath -split ";" | Where-Object { $_.Trim() -ne $INSTALL_DIR.Trim() }) -join ";"
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::Machine)
    Write-Host "  OK Usunieto $INSTALL_DIR z PATH"
} else {
    Write-Host "  INFO Brak wpisu w PATH, pomijam"
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
Write-Host "  OK Usunieto skojarzenia .eml i .msg"

# -- Usuniecie ProgID EML.Viewer --
$progIdPath = "$regBase\$PROG_ID"
if (Test-Path $progIdPath) {
    Remove-Item -Recurse -Force -Path $progIdPath
    Write-Host "  OK Usunieto ProgID $PROG_ID"
} else {
    Write-Host "  INFO ProgID $PROG_ID nie istnieje, pomijam"
}

# -- Usuniecie z RegisteredApplications --
$regAppPath = "HKLM:\Software\RegisteredApplications"
if ((Get-ItemProperty -Path $regAppPath -Name "WizualizatorEML" -ErrorAction SilentlyContinue) -ne $null) {
    Remove-ItemProperty -Path $regAppPath -Name "WizualizatorEML" -ErrorAction SilentlyContinue
    Write-Host "  OK Usunieto WizualizatorEML z RegisteredApplications"
} else {
    Write-Host "  INFO Brak wpisu w RegisteredApplications, pomijam"
}

# -- Usuniecie z Dodaj/Usun Programy (ARP) --
Write-Host "Usuwanie wpisu z Dodaj/Usun Programy..."
if (Test-Path $arpKey) {
    Remove-Item -Recurse -Force -Path $arpKey
    Write-Host "  OK Usunieto wpis z Dodaj/Usun Programy"
} else {
    Write-Host "  INFO Brak wpisu w ARP, pomijam"
}

# -- Powiadomienie Explorera --
Add-Type -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, uint f, IntPtr a, IntPtr b);' -Name WinAPI -Namespace Shell32 -ErrorAction SilentlyContinue
[Shell32.WinAPI]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
Write-Host "  OK Explorer powiadomiony o zmianie skojarzen"

Write-Host ""
Write-Host "Dezinstalacja zakonczona pomyslnie!"
