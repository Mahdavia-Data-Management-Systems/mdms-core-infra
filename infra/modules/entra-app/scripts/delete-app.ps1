. "$PSScriptRoot/app-helpers.ps1"

$token  = Get-GraphToken -TenantId $env:TENANT_ID `
                         -ClientId $env:CLIENT_ID `
                         -ClientSecret $env:CLIENT_SECRET

$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

$app = Get-AppByDisplayName -Headers $headers -DisplayName $env:DISPLAY_NAME

if ($null -eq $app) {
    Write-Host "App '$($env:DISPLAY_NAME)' not found — nothing to delete."
    exit 0
}

$sp = Get-ServicePrincipalByAppId -Headers $headers -AppId $app.appId
if ($null -ne $sp) {
  Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)" `
    -Method DELETE -Headers $headers
  Write-Host "Deleted service principal for app '$($env:DISPLAY_NAME)' (sp id: $($sp.id))"
}

$uri = "https://graph.microsoft.com/v1.0/applications/$($app.id)"
Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
Write-Host "Deleted app '$($env:DISPLAY_NAME)' (id: $($app.id))"
