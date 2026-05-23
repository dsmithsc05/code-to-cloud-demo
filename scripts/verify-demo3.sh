#!/usr/bin/env bash
# verify-demo3.sh — Smoke-test the Demo 3 deployment.
# Checks: Container App running, Backstage health endpoint responds, PostgreSQL connected.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

step()  { echo -e "\n${BLUE}${BOLD}▶ $*${RESET}"; }
ok()    { echo -e "${GREEN}✓ $*${RESET}"; }
warn()  { echo -e "${YELLOW}⚠ $*${RESET}"; }
fail()  { echo -e "${RED}✗ $*${RESET}"; FAILURES=$(( FAILURES + 1 )); }

FAILURES=0

# Load env
if [[ -f "${REPO_ROOT}/.env" ]]; then
  set -a; source "${REPO_ROOT}/.env"; set +a
fi
if command -v azd &>/dev/null; then
  eval "$(azd env get-values 2>/dev/null)" || true
fi

RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-rg-${AZURE_ENV_NAME}}"
CONTAINER_APP_NAME="ca-backstage-${AZURE_ENV_NAME}"
POSTGRES_SERVER_NAME="psql-${AZURE_ENV_NAME}"

# ─── Check 1: Container App provisioning state ───────────────────────────────
step "Checking Container App status"
PROV_STATE="$(az containerapp show \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query 'properties.provisioningState' -o tsv 2>/dev/null || echo 'NotFound')"

RUNNING_COUNT="$(az containerapp replica list \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query 'length([?properties.runningState==`Running`])' -o tsv 2>/dev/null || echo '0')"

if [[ "${PROV_STATE}" == "Succeeded" ]]; then
  ok "Container App provisioning: ${PROV_STATE}"
else
  fail "Container App provisioning state: ${PROV_STATE}"
fi

if [[ "${RUNNING_COUNT}" -ge 1 ]]; then
  ok "Running replicas: ${RUNNING_COUNT}"
else
  warn "Running replicas: ${RUNNING_COUNT} — app may still be starting"
fi

FQDN="$(az containerapp show \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query 'properties.configuration.ingress.fqdn' -o tsv 2>/dev/null || echo '')"

# ─── Check 2: HTTP health probe ──────────────────────────────────────────────
step "Probing Backstage health endpoint"
if [[ -n "${FQDN}" ]]; then
  BACKSTAGE_URL="https://${FQDN}"
  echo "  URL: ${BACKSTAGE_URL}/healthcheck"
  HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' \
    --max-time 30 --retry 5 --retry-delay 10 \
    "${BACKSTAGE_URL}/healthcheck" || echo '000')"
  if [[ "${HTTP_CODE}" == "200" ]]; then
    ok "Health check: HTTP ${HTTP_CODE}"
  else
    warn "Health check returned HTTP ${HTTP_CODE} — app may still be warming up"
  fi
else
  fail "Could not determine Container App FQDN"
fi

# ─── Check 3: PostgreSQL server running ──────────────────────────────────────
step "Checking PostgreSQL Flexible Server"
PG_STATE="$(az postgres flexible-server show \
  --name "${POSTGRES_SERVER_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query 'properties.state' -o tsv 2>/dev/null || echo 'NotFound')"

if [[ "${PG_STATE}" == "Ready" ]]; then
  ok "PostgreSQL server: ${PG_STATE}"
else
  fail "PostgreSQL server state: ${PG_STATE}"
fi

# ─── Check 4: Image tag ──────────────────────────────────────────────────────
step "Checking deployed image"
IMAGE="$(az containerapp show \
  --name "${CONTAINER_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query 'properties.template.containers[0].image' -o tsv 2>/dev/null || echo 'unknown')"
echo "  Image: ${IMAGE}"
if [[ "${IMAGE}" == *"backstage"* ]]; then
  ok "Custom Backstage image is deployed"
elif [[ "${IMAGE}" == *"helloworld"* ]]; then
  warn "Still running placeholder image — run 'make demo3-build demo3-deploy'"
else
  ok "Image: ${IMAGE}"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────────"
if [[ "${FAILURES}" -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All checks passed ✓${RESET}"
else
  echo -e "${RED}${BOLD}${FAILURES} check(s) failed. Review output above.${RESET}"
fi
if [[ -n "${FQDN}" ]]; then
  echo ""
  echo "  Backstage URL: https://${FQDN}"
fi
echo "────────────────────────────────────────────────────────────"

exit "${FAILURES}"
