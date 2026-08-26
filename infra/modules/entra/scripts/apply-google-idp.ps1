param()
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/idp-helpers.ps1"

$token   = Get-GraphToken -TenantId $env:TENANT_ID -ClientId $env:CLIENT_ID -ClientSecret $env:CLIENT_SECRET
$headers = @{ Authorization = "Bearer $token" }

Set-SocialIdentityProvider `
  -Headers         $headers `
  -ProviderType    'Google' `
  -DisplayName     'Google' `
  -IdpClientId     $env:GOOGLE_CLIENT_ID `
  -IdpClientSecret $env:GOOGLE_CLIENT_SECRET
