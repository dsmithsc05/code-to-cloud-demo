#!/usr/bin/env bash
# setup-demo3.sh — Full end-to-end provisioning for Demo 3 (Backstage portal).
# Runs all steps: prerequisite check → base infra → demo3 infra → build → deploy → verify.
#
# Usage:
#   ./scripts/setup-demo3.sh               # run all steps
#   ./scripts/setup-demo3.sh --infra-only  # stop after infra
#   ./scripts/setup-demo3.sh --skip-infra  # skip infra, only build+deploy
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

INFRA_ONLY=false
SKIP_INFRA=false
for arg in "$@"; do
  case $arg in
    --infra-only) INFRA_ONLY=true ;;
    --skip-infra) SKIP_INFRA=true ;;
  esac
done

# ─── Colours ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

step()  { echo -e "\n${BLUE}${BOLD}▶ $*${RESET}"; }
ok()    { echo -e "${GREEN}✓ $*${RESET}"; }
warn()  { echo -e "${YELLOW}⚠ $*${RESET}"; }
die()   { echo -e "${RED}✗ $*${RESET}" >&2; exit 1; }

# ─── 1. Prerequisites ─────────────────────────────────────────────────────────
step "Checking prerequisites"

command -v az      &>/dev/null || die "Azure CLI (az) is required. See https://docs.microsoft.com/cli/azure/install-azure-cli"
command -v azd     &>/dev/null || die "Azure Developer CLI (azd) is required. See https://aka.ms/azd"
command -v docker  &>/dev/null || die "Docker is required."
command -v jq      &>/dev/null || die "jq is required."

# Load .env if present
if [[ -f "${REPO_ROOT}/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/.env"
  set +a
  ok "Loaded .env"
else
  warn ".env not found — relying on exported environment variables"
fi

# Validate required env vars
REQUIRED_VARS=(
  AZURE_SUBSCRIPTION_ID
  AZURE_LOCATION
  AZURE_ENV_NAME
  AZURE_TENANT_ID
  BACKSTAGE_POSTGRES_PASSWORD
)
MISSING=()
for v in "${REQUIRED_VARS[@]}"; do
  [[ -z "${!v:-}" ]] && MISSING+=("$v")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  die "Missing required environment variables: ${MISSING[*]}\nCopy .env.sample → .env and fill in the values."
fi

ok "All required environment variables present"

# Confirm Azure login
az account show &>/dev/null || die "Not logged in to Azure CLI. Run: az login"
CURRENT_SUB="$(az account show --query id -o tsv)"
if [[ "${CURRENT_SUB}" != "${AZURE_SUBSCRIPTION_ID}" ]]; then
  die "Active subscription (${CURRENT_SUB}) != AZURE_SUBSCRIPTION_ID (${AZURE_SUBSCRIPTION_ID})\nRun: az account set --subscription ${AZURE_SUBSCRIPTION_ID}"
fi
ok "Azure CLI logged in — subscription: $(az account show --query name -o tsv)"

# ─── 2. Base infra (azd provision) ───────────────────────────────────────────
if [[ "${SKIP_INFRA}" == false ]]; then
  step "Provisioning base infrastructure (azd provision)"
  cd "${REPO_ROOT}"
  azd env select "${AZURE_ENV_NAME}" 2>/dev/null || \
    azd env new "${AZURE_ENV_NAME}" --subscription "${AZURE_SUBSCRIPTION_ID}" --location "${AZURE_LOCATION}"
  azd provision --no-prompt
  ok "Base infrastructure provisioned"

  # Capture azd outputs — fetch each variable individually to avoid eval of arbitrary shell code
  _load_azd_var() { azd env get-value "$1" 2>/dev/null || true; }
  AZURE_RESOURCE_GROUP="$(_load_azd_var AZURE_RESOURCE_GROUP)"
  AZURE_CONTAINER_REGISTRY_NAME="$(_load_azd_var AZURE_CONTAINER_REGISTRY_NAME)"
  AZURE_CONTAINER_REGISTRY_ENDPOINT="$(_load_azd_var AZURE_CONTAINER_REGISTRY_ENDPOINT)"
  AZURE_CONTAINER_APPS_ENVIRONMENT_ID="$(_load_azd_var AZURE_CONTAINER_APPS_ENVIRONMENT_ID)"
  AZURE_KEY_VAULT_NAME="$(_load_azd_var AZURE_KEY_VAULT_NAME)"
  APPLICATIONINSIGHTS_CONNECTION_STRING="$(_load_azd_var APPLICATIONINSIGHTS_CONNECTION_STRING)"
  export AZURE_RESOURCE_GROUP AZURE_CONTAINER_REGISTRY_NAME AZURE_CONTAINER_REGISTRY_ENDPOINT \
         AZURE_CONTAINER_APPS_ENVIRONMENT_ID AZURE_KEY_VAULT_NAME APPLICATIONINSIGHTS_CONNECTION_STRING

  # ─── 3. Demo 3 specific infra (PostgreSQL + Backstage Container App) ─────
  step "Provisioning Demo 3 infrastructure (PostgreSQL + Backstage Container App)"

  RESOURCE_GROUP="rg-${AZURE_ENV_NAME}"

  # Generate a random password if not provided
  BACKSTAGE_POSTGRES_PASSWORD="${BACKSTAGE_POSTGRES_PASSWORD:-}"
  if [[ -z "${BACKSTAGE_POSTGRES_PASSWORD}" ]]; then
    BACKSTAGE_POSTGRES_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=')Aa1!"
    warn "Generated PostgreSQL password. Add BACKSTAGE_POSTGRES_PASSWORD to your .env."
    echo "  BACKSTAGE_POSTGRES_PASSWORD=${BACKSTAGE_POSTGRES_PASSWORD}"
  fi

  az deployment group create \
    --resource-group "${RESOURCE_GROUP}" \
    --template-file "${REPO_ROOT}/infra/bicep/demo3.bicep" \
    --parameters \
      environmentName="${AZURE_ENV_NAME}" \
      location="${AZURE_LOCATION}" \
      containerRegistryName="${AZURE_CONTAINER_REGISTRY_NAME}" \
      keyVaultName="${AZURE_KEY_VAULT_NAME}" \
      containerAppsEnvironmentId="${AZURE_CONTAINER_APPS_ENVIRONMENT_ID}" \
      appInsightsConnectionString="${APPLICATIONINSIGHTS_CONNECTION_STRING}" \
      postgresPassword="${BACKSTAGE_POSTGRES_PASSWORD}" \
      msClientId="${AUTH_MICROSOFT_CLIENT_ID:-}" \
      msClientSecret="${AUTH_MICROSOFT_CLIENT_SECRET:-}" \
      msTenantId="${AUTH_MICROSOFT_TENANT_ID:-${AZURE_TENANT_ID}}" \
      githubToken="${GITHUB_TOKEN:-}" \
    --output json | tee /tmp/demo3-deploy-output.json

  POSTGRES_HOST="$(jq -r '.properties.outputs.POSTGRES_HOST.value' /tmp/demo3-deploy-output.json)"
  BACKSTAGE_NAME="$(jq -r '.properties.outputs.BACKSTAGE_NAME.value' /tmp/demo3-deploy-output.json)"
  BACKSTAGE_URI="$(jq -r '.properties.outputs.BACKSTAGE_URI.value' /tmp/demo3-deploy-output.json)"
  export POSTGRES_HOST BACKSTAGE_NAME BACKSTAGE_URI

  ok "Demo 3 infrastructure provisioned"
  echo "  PostgreSQL:  ${POSTGRES_HOST}"
  echo "  Backstage:   ${BACKSTAGE_URI}"

  if [[ "${INFRA_ONLY}" == true ]]; then
    echo -e "\n${GREEN}${BOLD}Infrastructure ready. Run './scripts/build-backstage.sh' to build and deploy.${RESET}"
    exit 0
  fi
fi

# ─── 4. Build & push Backstage image ─────────────────────────────────────────
step "Building and pushing Backstage Docker image"
"${SCRIPT_DIR}/build-backstage.sh"

# ─── 5. Deploy to Container Apps ─────────────────────────────────────────────
step "Deploying Backstage to Azure Container Apps"
"${SCRIPT_DIR}/deploy-backstage.sh"

# ─── 6. Verify ───────────────────────────────────────────────────────────────
step "Verifying deployment"
if ! "${SCRIPT_DIR}/verify-demo3.sh"; then
  warn "Some verification checks failed — the infrastructure and image are deployed."
  warn "Backstage may still be initialising. Re-run './scripts/verify-demo3.sh' in ~2 min."
fi

echo -e "\n${GREEN}${BOLD}✅ Demo 3 is live!${RESET}"
echo -e "   Backstage URL: ${BACKSTAGE_URI:-<check azd env get-values for BACKSTAGE_URI>}"
