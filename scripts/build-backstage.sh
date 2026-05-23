#!/usr/bin/env bash
# build-backstage.sh — Build the Backstage Docker image and push it to ACR.
# Expects AZURE_CONTAINER_REGISTRY_ENDPOINT and AZURE_ENV_NAME to be set
# (either exported or loaded from .env).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
step() { echo -e "\n${BLUE}${BOLD}▶ $*${RESET}"; }
ok()   { echo -e "${GREEN}✓ $*${RESET}"; }
die()  { echo -e "${RED}✗ $*${RESET}" >&2; exit 1; }

# Load .env if present
if [[ -f "${REPO_ROOT}/.env" ]]; then
  set -a; source "${REPO_ROOT}/.env"; set +a
fi

# Pull specific azd outputs if azd is available (no eval — avoids arbitrary code execution)
if command -v azd &>/dev/null; then
  _azd() { azd env get-value "$1" 2>/dev/null || true; }
  [[ -z "${AZURE_CONTAINER_REGISTRY_ENDPOINT:-}" ]] && AZURE_CONTAINER_REGISTRY_ENDPOINT="$(_azd AZURE_CONTAINER_REGISTRY_ENDPOINT)"
  [[ -z "${AZURE_CONTAINER_REGISTRY_NAME:-}" ]]     && AZURE_CONTAINER_REGISTRY_NAME="$(_azd AZURE_CONTAINER_REGISTRY_NAME)"
  [[ -z "${AZURE_ENV_NAME:-}" ]]                    && AZURE_ENV_NAME="$(_azd AZURE_ENV_NAME)"
  export AZURE_CONTAINER_REGISTRY_ENDPOINT AZURE_CONTAINER_REGISTRY_NAME AZURE_ENV_NAME
fi

[[ -z "${AZURE_CONTAINER_REGISTRY_ENDPOINT:-}" ]] && \
  die "AZURE_CONTAINER_REGISTRY_ENDPOINT is not set. Run 'azd provision' first."
[[ -z "${AZURE_ENV_NAME:-}" ]] && \
  die "AZURE_ENV_NAME is not set."

ACR_SERVER="${AZURE_CONTAINER_REGISTRY_ENDPOINT}"
IMAGE_TAG="${AZURE_ENV_NAME}-$(date +%Y%m%d%H%M%S)"
IMAGE_NAME="backstage"
FULL_IMAGE="${ACR_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"
LATEST_IMAGE="${ACR_SERVER}/${IMAGE_NAME}:latest"

step "Building Backstage image"
echo "  Context:    ${REPO_ROOT}"
echo "  Dockerfile: platform/backstage/Dockerfile"
echo "  Image:      ${FULL_IMAGE}"

docker build \
  --file "${REPO_ROOT}/platform/backstage/Dockerfile" \
  --tag "${FULL_IMAGE}" \
  --tag "${LATEST_IMAGE}" \
  --progress=plain \
  "${REPO_ROOT}"

ok "Docker image built: ${FULL_IMAGE}"

step "Logging into ACR"
az acr login --name "${AZURE_CONTAINER_REGISTRY_NAME:-${ACR_SERVER%%.*}}"
ok "ACR login successful"

step "Pushing image to ACR"
docker push "${FULL_IMAGE}"
docker push "${LATEST_IMAGE}"
ok "Image pushed: ${FULL_IMAGE}"

# Export for use by deploy-backstage.sh
export BACKSTAGE_IMAGE="${FULL_IMAGE}"
echo ""
echo "Image reference: ${FULL_IMAGE}"

# Write to temp file so deploy-backstage.sh can pick it up
echo "${FULL_IMAGE}" > /tmp/backstage-image-ref.txt
