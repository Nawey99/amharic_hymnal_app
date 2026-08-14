param(
  [Parameter(Mandatory = $true)][string]$SdaDump,
  [Parameter(Mandatory = $true)][string]$HagerignaDump,
  [Parameter(Mandatory = $true)][string]$SdaDatabaseUrl,
  [Parameter(Mandatory = $true)][string]$HagerignaDatabaseUrl
)

$ErrorActionPreference = "Stop"
foreach ($file in @($SdaDump, $HagerignaDump)) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
    throw "Backup file not found: $file"
  }
}

function Reset-PublicSchema([string]$DatabaseUrl, [string]$Label) {
  & psql --set ON_ERROR_STOP=1 --dbname $DatabaseUrl `
    --command "drop schema public cascade; create schema public;"
  if ($LASTEXITCODE -ne 0) { throw "$Label schema reset failed." }
}

Reset-PublicSchema $SdaDatabaseUrl "SDA"
& pg_restore --exit-on-error --single-transaction `
  --no-owner --no-privileges `
  --dbname $SdaDatabaseUrl $SdaDump
if ($LASTEXITCODE -ne 0) { throw "SDA restore failed." }

Reset-PublicSchema $HagerignaDatabaseUrl "Hagerigna"
& pg_restore --exit-on-error --single-transaction `
  --no-owner --no-privileges `
  --dbname $HagerignaDatabaseUrl $HagerignaDump
if ($LASTEXITCODE -ne 0) { throw "Hagerigna restore failed." }

Write-Host "Both content databases were restored."
