param()
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/app-helpers.ps1"

$token   = Get-GraphToken -TenantId $env:TENANT_ID -ClientId $env:CLIENT_ID -ClientSecret $env:CLIENT_SECRET
$headers = @{ Authorization = "Bearer $token" }

Remove-AppRegistration -Headers $headers -DisplayName $env:DISPLAY_NAME
