#Requires -Version 5.1
#Requires -RunAsAdministrator
# setup-windows-admin.ps1 - instaluje Wizualizator EML dla WSZYSTKICH uzytkownikow
#
# Uzycie (PowerShell jako Administrator):
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\setup-windows-admin.ps1

$ErrorActionPreference = "Stop"

$SCRIPT_SRC        = ".\eml-gmail.ps1"
$TEMPLATE_SRC      = ".\EML-Gmail.html"
$UNINSTALLER_SRC   = ".\uninstall-windows-admin.ps1"
$INSTALL_DIR       = "$env:ProgramFiles\eml-gmail"
$TEMPLATE_DST      = "$INSTALL_DIR\index.html"
$SCRIPT_DST        = "$INSTALL_DIR\eml-gmail.ps1"
$BAT_DST           = "$INSTALL_DIR\eml-gmail.bat"
$UNINSTALLER_DST   = "$INSTALL_DIR\uninstall.ps1"
$LAUNCHER_DST      = "$INSTALL_DIR\uninstall-launcher.bat"
$PROG_ID           = "EML.Viewer"
$iconPath          = "$env:SystemRoot\System32\shell32.dll,12"
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

if (Test-Path $UNINSTALLER_SRC) {
    Copy-Item $UNINSTALLER_SRC $UNINSTALLER_DST -Force
    Write-Host "  OK Dezinstalator zainstalowany"
} else {
    Write-Warning "  UWAGA: brak $UNINSTALLER_SRC - dezinstalator nie zostal skopiowany"
}

# -- Launcher dezinstalatora (prosba o UAC + widoczne okno) --
$launcherContent = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -Command " +
    "`"Start-Process powershell.exe -Verb RunAs " +
    "-ArgumentList @('-NonInteractive','-ExecutionPolicy','Bypass','-File','%~dp0uninstall.ps1')`"`r`n"
[System.IO.File]::WriteAllText($LAUNCHER_DST, $launcherContent, [System.Text.Encoding]::ASCII)
Write-Host "  OK Launcher dezinstalatora zainstalowany"

# -- Wrapper .bat --
$psExe = (Get-Command powershell.exe).Source
$batContent = "@echo off`r`n`"$psExe`" -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SCRIPT_DST`" %*`r`n"
[System.IO.File]::WriteAllText($BAT_DST, $batContent, [System.Text.Encoding]::ASCII)
Write-Host "  OK Wrapper eml-gmail.bat zainstalowany"

# -- Dodanie do PATH systemowego (HKLM) --
$sysPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
if ($sysPath -notlike "*$INSTALL_DIR*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$sysPath;$INSTALL_DIR", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "  OK Dodano $INSTALL_DIR do systemowego PATH"
} else {
    Write-Host "  OK PATH systemowy juz zawiera katalog instalacji"
}

# -- Rejestracja skojarzenia w HKLM --
Write-Host "Rejestracja skojarzen w HKLM..."
$openCmd = "`"$psExe`" -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SCRIPT_DST`" `"%1`""
$regBase = "HKLM:\Software\Classes"

foreach ($ext in @(".eml", ".msg")) {
    New-Item -Force -Path "$regBase\$ext"                          | Out-Null
    Set-ItemProperty -Path "$regBase\$ext" -Name "(Default)"       -Value $PROG_ID
    New-Item -Force -Path "$regBase\$ext\OpenWithProgids"          | Out-Null
    Set-ItemProperty -Path "$regBase\$ext\OpenWithProgids" -Name $PROG_ID -Value "" -Type String
}

New-Item -Force -Path "$regBase\$PROG_ID"                          | Out-Null
Set-ItemProperty -Path "$regBase\$PROG_ID" -Name "(Default)"       -Value "Wizualizator EML"
New-Item -Force -Path "$regBase\$PROG_ID\DefaultIcon"              | Out-Null
Set-ItemProperty -Path "$regBase\$PROG_ID\DefaultIcon" -Name "(Default)" -Value $iconPath
New-Item -Force -Path "$regBase\$PROG_ID\shell\open\command"       | Out-Null
Set-ItemProperty -Path "$regBase\$PROG_ID\shell\open\command" -Name "(Default)" -Value $openCmd

New-Item -Force -Path "HKLM:\Software\RegisteredApplications"     | Out-Null
Set-ItemProperty -Path "HKLM:\Software\RegisteredApplications" -Name "WizualizatorEML" `
    -Value "Software\Classes\$PROG_ID"
Write-Host "  OK Skojarzenia .eml i .msg -> $PROG_ID zarejestrowane"

# -- Rejestracja w Dodaj/Usun Programy (ARP) --
Write-Host "Rejestracja w Dodaj/Usun Programy..."
$arpKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WizualizatorEML"
New-Item -Force -Path $arpKey | Out-Null
Set-ItemProperty -Path $arpKey -Name "DisplayName"          -Value "Wizualizator EML"
Set-ItemProperty -Path $arpKey -Name "DisplayVersion"       -Value "1.0"
Set-ItemProperty -Path $arpKey -Name "Publisher"            -Value "eml-gmail"
Set-ItemProperty -Path $arpKey -Name "InstallDate"          -Value (Get-Date -Format "yyyyMMdd")
Set-ItemProperty -Path $arpKey -Name "InstallLocation"      -Value $INSTALL_DIR
Set-ItemProperty -Path $arpKey -Name "DisplayIcon"          -Value $iconPath
Set-ItemProperty -Path $arpKey -Name "NoModify"             -Value 1 -Type DWord
Set-ItemProperty -Path $arpKey -Name "NoRepair"             -Value 1 -Type DWord

# Interaktywny: launcher .bat pyta o UAC i pokazuje okno PowerShell
Set-ItemProperty -Path $arpKey -Name "UninstallString" `
    -Value "`"$LAUNCHER_DST`""

# Cichy: bezposrednie wywolanie ps1 (dla RMM/Intune uruchamianych jako SYSTEM)
Set-ItemProperty -Path $arpKey -Name "QuietUninstallString" `
    -Value "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$UNINSTALLER_DST`""

Write-Host "  OK Zarejestrowano w Dodaj/Usun Programy"

# -- Powiadomienie Explorera --
Add-Type -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, uint f, IntPtr a, IntPtr b);' -Name WinAPI -Namespace Shell32 -ErrorAction SilentlyContinue
[Shell32.WinAPI]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
Write-Host "  OK Explorer powiadomiony o zmianie skojarzen"

Write-Host ""
Write-Host "Instalacja zakonczona!"
Write-Host "  Skrypt        : $SCRIPT_DST"
Write-Host "  Szablon       : $TEMPLATE_DST"
Write-Host "  Dezinstalator : $UNINSTALLER_DST"
Write-Host "  Launcher UAC  : $LAUNCHER_DST"
