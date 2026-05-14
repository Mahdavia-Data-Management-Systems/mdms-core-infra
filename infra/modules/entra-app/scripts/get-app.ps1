param()
$ErrorActionPreference = 'Stop'

# The external data source protocol: read JSON query from stdin, write JSON result to stdout.
$query        = [Console]::In.ReadToEnd() | ConvertFrom-Json
$tenantId     = $query.tenant_id
$clientId     = $query.client_id
$clientSecret = $query.client_secret
$displayName  = $query.display_name

. "$PSScriptRoot/app-helpers.ps1"

$token   = Get-GraphToken -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret
$headers = @{ Authorization = "Bearer $token" }

$app = Get-AppByDisplayName -Headers $headers -DisplayName $displayName

if ($null -eq $app) {
  Write-Error "Application '$displayName' not found in tenant $tenantId"
  exit 1
}

@{ app_id = $app.appId; object_id = $app.id } | ConvertTo-Json -Compress
