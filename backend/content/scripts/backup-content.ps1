param(
  [Parameter(Mandatory = $true)][string]$SdaDatabaseUrl,
  [Parameter(Mandatory = $true)][string]$HagerignaDatabaseUrl,
  [string]$OutputDirectory = ".\content-backups"
)

$ErrorActionPreference = "Stop"
$resolved = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $resolved | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

& pg_dump --format=custom --no-owner --no-privileges `
  --file (Join-Path $resolved "wudase-sda-$timestamp.dump") `
  --dbname $SdaDatabaseUrl
if ($LASTEXITCODE -ne 0) { throw "SDA backup failed." }

& pg_dump --format=custom --no-owner --no-privileges `
  --file (Join-Path $resolved "wudase-hagerigna-$timestamp.dump") `
  --dbname $HagerignaDatabaseUrl
if ($LASTEXITCODE -ne 0) { throw "Hagerigna backup failed." }

Write-Host "Content backups written to $resolved"
