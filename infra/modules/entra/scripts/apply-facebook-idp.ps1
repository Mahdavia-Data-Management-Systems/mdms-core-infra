param()
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/idp-helpers.ps1"

$token   = Get-GraphToken -TenantId $env:TENANT_ID -ClientId $env:CLIENT_ID -ClientSecret $env:CLIENT_SECRET
$headers = @{ Authorization = "Bearer $token" }

Set-SocialIdentityProvider `
  -Headers         $headers `
  -ProviderType    'Facebook' `
  -DisplayName     'Login with Facebook' `
  -IdpClientId     $env:FACEBOOK_CLIENT_ID `
  -IdpClientSecret $env:FACEBOOK_CLIENT_SECRET
