#!/usr/bin/env bash
set -e

echo "🌱 Post-provision: seeding Key Vault and reporting service URL…"

# Pull azd outputs into the current shell.
# `azd env get-values` prints KEY="value" lines.
eval "$(azd env get-values 2>/dev/null || true)"

KV_NAME="${AZURE_KEY_VAULT_NAME:-}"
API_URI="${SERVICE_API_URI:-}"

if [[ -n "${KV_NAME}" ]]; then
  echo "  • Seeding example secrets in Key Vault: ${KV_NAME}"
  az keyvault secret set --vault-name "${KV_NAME}" --name "api-greeting"  --value "hello from azd" --output none || true
  az keyvault secret set --vault-name "${KV_NAME}" --name "feature-newui" --value "true"            --output none || true
  echo "  • Secrets seeded: api-greeting, feature-newui"
else
  echo "  • AZURE_KEY_VAULT_NAME not set — skipping secret seed."
fi

if [[ -n "${API_URI}" ]]; then
  echo ""
  echo "🚀 Service deployed: ${API_URI}"
  echo "   Try: curl ${API_URI}/health"
else
  echo "  • SERVICE_API_URI not set yet — deploy hasn't happened."
fi

exit 0
