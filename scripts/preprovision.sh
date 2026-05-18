#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Pre-provision checks…"

# 1. Confirm we're logged in to Azure CLI.
if ! az account show >/dev/null 2>&1; then
  echo "ERROR: not logged in to Azure CLI. Run 'az login' first." >&2
  exit 1
fi

CURRENT_SUB="$(az account show --query id -o tsv)"
CURRENT_SUB_NAME="$(az account show --query name -o tsv)"
echo "  • Active subscription: ${CURRENT_SUB_NAME} (${CURRENT_SUB})"

# 2. If AZURE_SUBSCRIPTION_ID is pinned, it must match the active sub.
if [[ -n "${AZURE_SUBSCRIPTION_ID:-}" ]]; then
  if [[ "${AZURE_SUBSCRIPTION_ID}" != "${CURRENT_SUB}" ]]; then
    echo "ERROR: AZURE_SUBSCRIPTION_ID (${AZURE_SUBSCRIPTION_ID}) does not match the active subscription (${CURRENT_SUB})." >&2
    echo "       Run: az account set --subscription ${AZURE_SUBSCRIPTION_ID}" >&2
    exit 1
  fi
  echo "  • Subscription pin matches: OK"
fi

# 3. Region must be one we've validated for this demo.
ALLOWED_REGIONS=("canadacentral" "canadaeast" "eastus2")
REGION="${AZURE_LOCATION:-canadacentral}"
REGION_OK=0
for r in "${ALLOWED_REGIONS[@]}"; do
  if [[ "${REGION}" == "${r}" ]]; then
    REGION_OK=1
    break
  fi
done
if [[ "${REGION_OK}" -ne 1 ]]; then
  echo "ERROR: AZURE_LOCATION='${REGION}' is not in the allowed list: ${ALLOWED_REGIONS[*]}" >&2
  exit 1
fi
echo "  • Region: ${REGION} (allowed)"

# 4. Tell the operator what's about to happen.
ENV_NAME="${AZURE_ENV_NAME:-<unset>}"
echo ""
echo "  About to provision azd environment: ${ENV_NAME}"
echo "    Resource group: rg-${ENV_NAME}"
echo "    Region:         ${REGION}"
echo "    Resources:      Log Analytics, App Insights, Key Vault, ACR, Container Apps Env, 1 Container App"
echo ""

echo "✅ Pre-provision checks passed"
