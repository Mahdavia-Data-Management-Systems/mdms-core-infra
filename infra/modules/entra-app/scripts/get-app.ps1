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

$app       = $null
$attempts  = 10
$delaySecs = 6
for ($i = 1; $i -le $attempts; $i++) {
  $app = Get-AppByDisplayName -Headers $headers -DisplayName $displayName
  if ($null -ne $app) { break }
  if ($i -lt $attempts) {
    [Console]::Error.WriteLine("App '$displayName' not yet visible (attempt $i/$attempts); retrying in ${delaySecs}s...")
    Start-Sleep -Seconds $delaySecs
  }
}

if ($null -eq $app) {
  Write-Error "Application '$displayName' not found in tenant $tenantId after $attempts attempts"
  exit 1
}

$sp = Get-ServicePrincipalByAppId -Headers $headers -AppId $app.appId

@{
  app_id                      = $app.appId
  object_id                   = $app.id
  service_principal_object_id = if ($null -ne $sp) { $sp.id } else { "" }
} | ConvertTo-Json -Compress
