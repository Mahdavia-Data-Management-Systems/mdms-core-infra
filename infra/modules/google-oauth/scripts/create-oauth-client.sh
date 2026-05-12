#!/usr/bin/env bash
# Creates a Google OAuth2 CONFIDENTIAL_CLIENT with the redirect URIs required for
# Microsoft Entra External ID federation, then stores the credentials in Secret Manager.
#
# Environment variables (set by Terraform local-exec):
#   PROJECT_ID    - GCP project ID
#   DISPLAY_NAME  - OAuth client display name
#   REDIRECT_URIS - Comma-separated list of authorized redirect URIs
#   SECRET_NAME   - Full Secret Manager secret resource name
#                   (projects/<number>/secrets/<secret_id>)
#
# Idempotent: if the secret already has an enabled version, exits without
# creating a new client (assumes credentials were already provisioned).
set -euo pipefail

echo "Checking for existing OAuth credentials in Secret Manager..."

VERSIONS=$(gcloud secrets versions list "${SECRET_NAME}" \
  --filter="state=ENABLED" --format="value(name)" 2>/dev/null | wc -l || echo "0")

if [[ "${VERSIONS}" -gt 0 ]]; then
  echo "Credentials already present in Secret Manager — skipping client creation."
  exit 0
fi

echo "No existing credentials found. Creating OAuth2 client..."

# Ensure gcloud alpha component is available.
gcloud components install alpha --quiet 2>/dev/null || true

# Build --allowed-redirect-uris flags from comma-separated input.
REDIRECT_FLAGS=()
IFS=',' read -ra URIS <<< "${REDIRECT_URIS}"
for URI in "${URIS[@]}"; do
  REDIRECT_FLAGS+=("--allowed-redirect-uris=${URI}")
done

# Create the OAuth2 confidential client.
CLIENT_JSON=$(gcloud alpha oauth-clients create \
  --project="${PROJECT_ID}" \
  --display-name="${DISPLAY_NAME}" \
  --client-type=CONFIDENTIAL_CLIENT \
  "${REDIRECT_FLAGS[@]}" \
  --format=json)

CLIENT_ID=$(echo "${CLIENT_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('clientId', d.get('client_id', '')))")
CLIENT_SECRET=$(echo "${CLIENT_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('clientSecret', d.get('client_secret', '')))")

if [[ -z "${CLIENT_ID}" || -z "${CLIENT_SECRET}" ]]; then
  echo "ERROR: Failed to extract client_id or client_secret from gcloud output."
  echo "gcloud output was: ${CLIENT_JSON}"
  exit 1
fi

# Store credentials as JSON in Secret Manager.
CREDS_JSON="{\"client_id\":\"${CLIENT_ID}\",\"client_secret\":\"${CLIENT_SECRET}\"}"
printf '%s' "${CREDS_JSON}" | gcloud secrets versions add "${SECRET_NAME}" --data-file=-

echo "OAuth2 client '${DISPLAY_NAME}' created and credentials stored in Secret Manager."
echo "Client ID: ${CLIENT_ID}"
