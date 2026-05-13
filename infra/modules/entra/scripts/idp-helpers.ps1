function Get-GraphToken {
  param([string]$TenantId, [string]$ClientId, [string]$ClientSecret)
  $r = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body "client_id=$ClientId&client_secret=$ClientSecret&scope=https://graph.microsoft.com/.default&grant_type=client_credentials"
  return $r.access_token
}

function Set-SocialIdentityProvider {
  param(
    [hashtable]$Headers,
    [string]$ProviderType,
    [string]$DisplayName,
    [string]$IdpClientId,
    [string]$IdpClientSecret
  )
  if ([string]::IsNullOrWhiteSpace($IdpClientId)) {
    Write-Host "$ProviderType IDP skipped — IdpClientId not provided."
    return
  }
  $idpBase = "https://graph.microsoft.com/v1.0/identity/identityProviders"
  $existing = Invoke-RestMethod -Method Get -Uri $idpBase -Headers $Headers
  $idp = $existing.value | Where-Object { $_.identityProviderType -eq $ProviderType }

  if ($null -eq $idp) {
    Write-Host "$ProviderType identity provider not found — creating..."
    $body = @{
      '@odata.type'        = 'microsoft.graph.socialIdentityProvider'
      displayName          = $DisplayName
      identityProviderType = $ProviderType
      clientId             = $IdpClientId
      clientSecret         = $IdpClientSecret
    } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri $idpBase -Headers $Headers -ContentType 'application/json' -Body $body | Out-Null
    Write-Host "$ProviderType identity provider created in tenant."
  } else {
    Write-Host "$ProviderType identity provider already exists (id: $($idp.id)) — updating credentials..."
    $body = @{ clientId = $IdpClientId; clientSecret = $IdpClientSecret } | ConvertTo-Json
    Invoke-RestMethod -Method Patch -Uri "$idpBase/$($idp.id)" -Headers $Headers -ContentType 'application/json' -Body $body | Out-Null
    Write-Host "$ProviderType identity provider credentials updated."
  }
}
