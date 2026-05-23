#!/usr/bin/env bash
# deploy-backstage.sh — Update the Backstage Container App to use the newly built image.
# Expects AZURE_ENV_NAME and AZURE_CONTAINER_REGISTRY_ENDPOINT to be set.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
step() { echo -e "\n${BLUE}${BOLD}▶ $*${RESET}"; }
ok()   { echo -e "${GREEN}✓ $*${RESET}"; }
die()  { echo -e "${RED}✗ $*${RESET}" >&2; exit 1; }

# Load env
if [[ -f "${REPO_ROOT}/.env" ]]; then
  set -a; source "${REPO_ROOT}/.env"; set +a
fi
if command -v azd &>/dev/null; then
  _azd() { azd env get-value "$1" 2>/dev/null || true; }
  [[ -z "${AZURE_ENV_NAME:-}" ]]              && AZURE_ENV_NAME="$(_azd AZURE_ENV_NAME)"
  [[ -z "${AZURE_RESOURCE_GROUP:-}" ]]        && AZURE_RESOURCE_GROUP="$(_azd AZURE_RESOURCE_GROUP)"
  [[ -z "${AZURE_CONTAINER_REGISTRY_ENDPOINT:-}" ]] && AZURE_CONTAINER_REGISTRY_ENDPOINT="$(_azd AZURE_CONTAINER_REGISTRY_ENDPOINT)"
  export AZURE_ENV_NAME AZURE_RESOURCE_GROUP AZURE_CONTAINER_REGISTRY_ENDPOINT
fi

[[ -z "${AZURE_ENV_NAME:-}" ]]         && die "AZURE_ENV_NAME is not set."
[[ -z "${AZURE_RESOURCE_GROUP:-}" ]]   && AZURE_RESOURCE_GROUP="rg-${AZURE_ENV_NAME}"

CONTAINER_APP_NAME="ca-backstage-${AZURE_ENV_NAME}"

# Resolve image — prefer env var, fall back to temp file from build step
if [[ -n "${BACKSTAGE_IMAGE:-}" ]]; then
  IMAGE="${BACKSTAGE_IMAGE}"
elif [[ -f /tmp/backstage-image-ref.txt ]]; then
  IMAGE="$(cat /tmp/backstage-image-ref.txt)"
else
  # Fall back to :latest
  [[ -z "${AZURE_CONTAINER_REGISTRY_ENDPOINT:-}" ]] && \
    die "AZURE_CONTAINER_REGISTRY_ENDPOINT is not set."
  IMAGE="${AZURE_CONTAINER_REGISTRY_ENDPOINT}/backstage:latest"
fi

step "Updating Container App image"
echo "  App:   ${CONTAINER_APP_NAME}"
echo "  Group: ${AZURE_RESOURCE_GROUP}"
echo "  Image: ${IMAGE}"

az containerapp update \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --image "${IMAGE}" \
  --output table

ok "Container App updated — new revision deploying"

step "Waiting for revision to become active (up to 5 min)"
DEADLINE=$(( $(date +%s) + 300 ))
while true; do
  PROVISIONING="$(az containerapp show \
    --name "${CONTAINER_APP_NAME}" \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --query 'properties.provisioningState' -o tsv 2>/dev/null || echo 'Unknown')"

  if [[ "${PROVISIONING}" == "Succeeded" ]]; then
    ok "Provisioning state: Succeeded"
    break
  fi
  if [[ $(date +%s) -gt ${DEADLINE} ]]; then
    echo "Timeout waiting for provisioning — check Azure Portal for details."
    break
  fi
  echo "  State: ${PROVISIONING} — waiting…"
  sleep 15
done

FQDN="$(az containerapp show \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --query 'properties.configuration.ingress.fqdn' -o tsv 2>/dev/null || echo '')"

if [[ -n "${FQDN}" ]]; then
  BACKSTAGE_URL="https://${FQDN}"
  echo ""
  ok "Backstage is deploying at: ${BACKSTAGE_URL}"

  # Inject the real base URL now that the FQDN is known.
  # app-config.yaml substitutes BACKSTAGE_BASE_URL and BACKSTAGE_BACKEND_BASE_URL at startup.
  step "Updating BACKSTAGE_BASE_URL env vars with resolved FQDN"
  az containerapp update \
    --name "${CONTAINER_APP_NAME}" \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --set-env-vars \
      "BACKSTAGE_BASE_URL=${BACKSTAGE_URL}" \
      "BACKSTAGE_BACKEND_BASE_URL=${BACKSTAGE_URL}" \
    --output none
  ok "Base URL env vars updated → ${BACKSTAGE_URL}"
fi
