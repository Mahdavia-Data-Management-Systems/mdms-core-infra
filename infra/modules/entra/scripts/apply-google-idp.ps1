param()
$ErrorActionPreference = 'Stop'

# ── Token ─────────────────────────────────────────────────────────────────────
$tokenResponse = Invoke-RestMethod -Method Post `
  -Uri "https://login.microsoftonline.com/$env:TENANT_ID/oauth2/v2.0/token" `
  -ContentType 'application/x-www-form-urlencoded' `
  -Body "client_id=$env:CLIENT_ID&client_secret=$env:CLIENT_SECRET&scope=https://graph.microsoft.com/.default&grant_type=client_credentials"
$token = $tokenResponse.access_token

$headers = @{ Authorization = "Bearer $token" }
$idpBase = "https://graph.microsoft.com/v1.0/identity/identityProviders"

# ── Check for existing Google identity provider ───────────────────────────────
$existing = Invoke-RestMethod -Method Get -Uri $idpBase -Headers $headers
$googleIdP = $existing.value | Where-Object { $_.identityProviderType -eq 'Google' }

if ($null -eq $googleIdP) {
  Write-Host "Google identity provider not found — creating..."

  $body = @{
    '@odata.type'        = 'microsoft.graph.socialIdentityProvider'
    displayName          = 'Google'
    identityProviderType = 'Google'
    clientId             = $env:GOOGLE_CLIENT_ID
    clientSecret         = $env:GOOGLE_CLIENT_SECRET
  } | ConvertTo-Json

  Invoke-RestMethod -Method Post -Uri $idpBase `
    -Headers $headers `
    -ContentType 'application/json' `
    -Body $body | Out-Null

  Write-Host "Google identity provider created in tenant $env:TENANT_ID."
} else {
  Write-Host "Google identity provider already exists (id: $($googleIdP.id)) — updating credentials..."

  $body = @{
    clientId     = $env:GOOGLE_CLIENT_ID
    clientSecret = $env:GOOGLE_CLIENT_SECRET
  } | ConvertTo-Json

  Invoke-RestMethod -Method Patch -Uri "$idpBase/$($googleIdP.id)" `
    -Headers $headers `
    -ContentType 'application/json' `
    -Body $body | Out-Null

  Write-Host "Google identity provider credentials updated in tenant $env:TENANT_ID."
}
