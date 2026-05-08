param()
$ErrorActionPreference = 'Stop'

# ── Token ────────────────────────────────────────────────────────────────
$tokenResponse = Invoke-RestMethod -Method Post `
  -Uri "https://login.microsoftonline.com/$env:TENANT_ID/oauth2/v2.0/token" `
  -ContentType 'application/x-www-form-urlencoded' `
  -Body "client_id=$env:CLIENT_ID&client_secret=$env:CLIENT_SECRET&scope=https://graph.microsoft.com/.default&grant_type=client_credentials"
$token = $tokenResponse.access_token

$headers = @{ Authorization = "Bearer $token" }
$graph   = "https://graph.microsoft.com/v1.0/organization/$env:TENANT_ID"

# ── Text + colour properties ──────────────────────────────────────────────
$patchBody = @{
  backgroundColor  = '#0F3D2E'
  signInPageText   = $env:SIGN_IN_TEXT
  usernameHintText = 'Enter your email'
} | ConvertTo-Json

Invoke-RestMethod -Method Patch -Uri "$graph/branding" `
  -Headers ($headers + @{ 'Accept-Language' = '0' }) `
  -ContentType 'application/json' `
  -Body $patchBody

# ── Custom CSS ────────────────────────────────────────────────────────────
Invoke-RestMethod -Method Put -Uri "$graph/branding/localizations/0/customCSS" `
  -Headers $headers `
  -ContentType 'text/css' `
  -Body ([System.IO.File]::ReadAllBytes($env:CSS_PATH))

# ── Images (skipped when asset files are absent) ──────────────────────────
function Upload-Asset($file, $endpoint, $mime) {
  $path = Join-Path $env:ASSETS_DIR $file
  if (-not (Test-Path $path)) { return }
  Invoke-RestMethod -Method Put -Uri "$graph/branding/localizations/0/$endpoint" `
    -Headers $headers `
    -ContentType $mime `
    -Body ([System.IO.File]::ReadAllBytes($path))
  Write-Host "Uploaded $file"
}

Upload-Asset background.jpg  backgroundImage image/jpeg
Upload-Asset banner-logo.png bannerLogo      image/png
Upload-Asset square-logo.jpg squareLogo      image/jpeg
Upload-Asset favicon.ico     favicon         image/vnd.microsoft.icon

Write-Host "Branding applied to tenant $env:TENANT_ID."
