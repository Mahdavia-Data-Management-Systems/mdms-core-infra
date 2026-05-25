param()
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/app-helpers.ps1"

$token   = Get-GraphToken -TenantId $env:TENANT_ID -ClientId $env:CLIENT_ID -ClientSecret $env:CLIENT_SECRET
$headers = @{ Authorization = "Bearer $token" }

Set-AppRegistration `
  -Headers         $headers `
  -DisplayName     $env:DISPLAY_NAME `
  -AppType         $env:APP_TYPE `
  -RedirectUris    ($env:REDIRECT_URIS | ConvertFrom-Json) `
  -LogoutUrl       $env:LOGOUT_URL `
  -SignInAudience  $env:SIGN_IN_AUDIENCE

$app = Get-AppByDisplayName -Headers $headers -DisplayName $env:DISPLAY_NAME
if ($null -ne $app) {
  Set-ServicePrincipal -Headers $headers -AppId $app.appId
}
