function Get-GraphToken {
  param([string]$TenantId, [string]$ClientId, [string]$ClientSecret)
  $r = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body "client_id=$ClientId&client_secret=$ClientSecret&scope=https://graph.microsoft.com/.default&grant_type=client_credentials"
  return $r.access_token
}

function Get-AppByDisplayName {
  param([hashtable]$Headers, [string]$DisplayName)
  $uri    = "https://graph.microsoft.com/v1.0/applications?`$filter=displayName eq '$DisplayName'"
  $result = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers
  return $result.value | Select-Object -First 1
}

function Get-ServicePrincipalByAppId {
  param([hashtable]$Headers, [string]$AppId)
  $uri    = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$AppId'"
  $result = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers
  return $result.value | Select-Object -First 1
}

function Set-ServicePrincipal {
  param([hashtable]$Headers, [string]$AppId)
  $sp = Get-ServicePrincipalByAppId -Headers $Headers -AppId $AppId
  if ($null -eq $sp) {
    Write-Host "Service principal for appId '$AppId' not found — creating..."
    $body = @{ appId = $AppId } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post `
      -Uri 'https://graph.microsoft.com/v1.0/servicePrincipals' `
      -Headers $Headers `
      -ContentType 'application/json' `
      -Body $body | Out-Null
    Write-Host "Service principal created."
  } else {
    Write-Host "Service principal for appId '$AppId' already exists (id: $($sp.id)) — no changes needed."
  }
}

function Set-AppRegistration {
  param(
    [hashtable]$Headers,
    [string]$DisplayName,
    [string]$AppType,
    [string[]]$RedirectUris,
    [string]$LogoutUrl,
    [string]$SignInAudience
  )

  $existing = Get-AppByDisplayName -Headers $Headers -DisplayName $DisplayName

  $implicitGrant = @{ enableAccessTokenIssuance = $true; enableIdTokenIssuance = $true }

  $redirectBlock = if ($AppType -eq 'spa') {
    @{ spa = @{ redirectUris = @($RedirectUris) }; web = @{ implicitGrantSettings = $implicitGrant } }
  } else {
    $web = @{ redirectUris = @($RedirectUris); implicitGrantSettings = $implicitGrant }
    if ($LogoutUrl) { $web.logoutUrl = $LogoutUrl }
    @{ web = $web }
  }

  if ($null -eq $existing) {
    Write-Host "Application '$DisplayName' not found — creating..."
    $body = @{ displayName = $DisplayName; signInAudience = $SignInAudience; web = @{ implicitGrantSettings = $implicitGrant } }
    $redirectKey = if ($AppType -eq 'spa') { 'spa' } else { 'web' }
    $body[$redirectKey] = $redirectBlock[$redirectKey]
    Invoke-RestMethod -Method Post `
      -Uri 'https://graph.microsoft.com/v1.0/applications' `
      -Headers $Headers `
      -ContentType 'application/json' `
      -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
    Write-Host "Application '$DisplayName' created."
  } else {
    Write-Host "Application '$DisplayName' exists (appId: $($existing.appId)) — updating..."
    Invoke-RestMethod -Method Patch `
      -Uri "https://graph.microsoft.com/v1.0/applications/$($existing.id)" `
      -Headers $Headers `
      -ContentType 'application/json' `
      -Body ($redirectBlock | ConvertTo-Json -Depth 5) | Out-Null
    Write-Host "Application '$DisplayName' updated."
  }
}
