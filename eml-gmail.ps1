#Requires -Version 5.1
# eml-gmail.ps1 — otwiera plik .eml jako lokalny podgląd HTML
#
# Instalacja:
#   powershell -ExecutionPolicy Bypass -File setup-windows.ps1
#
# Użycie:
#   powershell -File eml-gmail.ps1 C:\Pobrane\wiadomosc.eml

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$EmlFile
)

$TEMPLATE    = "$env:LOCALAPPDATA\eml-gmail\index.html"
$MAX_SIZE_MB = 30

# ── Sprawdzenie pliku ──
if (-not (Test-Path $EmlFile)) {
    Write-Error "Błąd: plik nie istnieje: $EmlFile"
    exit 1
}
if (-not (Test-Path $TEMPLATE)) {
    Write-Error "Błąd: brak szablonu: $TEMPLATE`nUruchom: setup-windows.ps1"
    exit 1
}

# ── Sprawdzenie rozmiaru ──
$sizeBytes = (Get-Item $EmlFile).Length
$sizeMB    = $sizeBytes / 1MB
if ($sizeMB -ge $MAX_SIZE_MB) {
    Write-Error "Błąd: plik za duży ($([math]::Round($sizeMB, 1)) MB). Limit: $MAX_SIZE_MB MB."
    exit 1
}

Write-Host "Rozmiar pliku: $sizeBytes B"

# ── Kodowanie Base64 (wbudowane w PowerShell — bez Pythona) ──
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $EmlFile).Path)
$b64   = [System.Convert]::ToBase64String($bytes)
Write-Host "base64: $($b64.Length) znaków"

# ── Wstrzykiwanie danych do szablonu HTML ──
$filename = [System.IO.Path]::GetFileName($EmlFile) -replace '"', '\"'
$html     = [System.IO.File]::ReadAllText($TEMPLATE, [System.Text.Encoding]::UTF8)
$inject   = "<script>window.EMBEDDED_EML=""$b64"";window.EMBEDDED_EML_NAME=""$filename"";</script>"
$html     = $html.Replace('</head>', "$inject`n</head>")

# ── Zapis tymczasowego pliku HTML ──
$tmpFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "eml-gmail-$PID.html")
[System.IO.File]::WriteAllText($tmpFile, $html, [System.Text.Encoding]::UTF8)

Write-Host "Otwieranie przeglądarki..."
Start-Process $tmpFile

# ── Usunięcie pliku tymczasowego po 5 sekundach (w tle) ──
$job = Start-Job -ScriptBlock {
    param($f)
    Start-Sleep 5
    Remove-Item $f -Force -ErrorAction SilentlyContinue
} -ArgumentList $tmpFile
$job | Out-Null
