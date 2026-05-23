# ============================================================
# Meridian Pay — Code to Cloud Demo
# ============================================================
# Quick-reference commands. Run 'make help' to see all targets.
# Prerequisites: az, azd, docker, jq, node 18+, yarn 1.x

.PHONY: help \
        demo2 demo2-provision demo2-deploy demo2-verify \
        demo3 demo3-infra demo3-build demo3-deploy demo3-verify \
        local-dev local-api local-backstage \
        test lint clean

SHELL := /usr/bin/env bash
REPO_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# ─── Help ────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  Meridian Pay — Code to Cloud Demo"
	@echo ""
	@echo "  Demo 2 (API → Azure Container Apps):"
	@echo "    make demo2              Full provision + deploy + verify"
	@echo "    make demo2-provision    azd provision only"
	@echo "    make demo2-deploy       azd deploy only"
	@echo "    make demo2-verify       Smoke-test the API endpoint"
	@echo ""
	@echo "  Demo 3 (Backstage Developer Portal):"
	@echo "    make demo3              Full setup: infra + build + deploy + verify"
	@echo "    make demo3-infra        Provision PostgreSQL + Backstage Container App"
	@echo "    make demo3-build        Build & push Backstage Docker image to ACR"
	@echo "    make demo3-deploy       Update Container App with new image"
	@echo "    make demo3-verify       Smoke-test the Backstage deployment"
	@echo ""
	@echo "  Local development:"
	@echo "    make local-api          Run the .NET API locally (port 8080)"
	@echo "    make local-backstage    Run Backstage dev server (ports 3000 + 7007)"
	@echo ""
	@echo "  Quality:"
	@echo "    make test               Run all tests (.NET + Backstage)"
	@echo "    make lint               Lint Backstage TypeScript"
	@echo ""

# ─── Demo 2 ──────────────────────────────────────────────────────────────────
demo2: demo2-provision demo2-deploy demo2-verify

demo2-provision:
	@echo "▶ Provisioning base Azure infrastructure…"
	azd provision --no-prompt

demo2-deploy:
	@echo "▶ Building and deploying API to Container Apps…"
	azd deploy --no-prompt

demo2-verify:
	@echo "▶ Verifying API deployment…"
	@API_URI="$$(azd env get-value SERVICE_API_URI 2>/dev/null)"; \
	if [[ -z "$$API_URI" ]]; then echo "SERVICE_API_URI not set — run 'make demo2-provision' first"; exit 1; fi; \
	echo "  Hitting $$API_URI/health"; \
	HTTP="$$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$$API_URI/health")"; \
	if [[ "$$HTTP" == "200" ]]; then echo "✓ API healthy (HTTP 200)"; else echo "✗ Expected 200, got $$HTTP"; exit 1; fi

# ─── Demo 3 ──────────────────────────────────────────────────────────────────
demo3:
	@echo "▶ Running full Demo 3 setup…"
	@chmod +x scripts/setup-demo3.sh scripts/build-backstage.sh \
	          scripts/deploy-backstage.sh scripts/verify-demo3.sh
	./scripts/setup-demo3.sh

demo3-infra:
	@echo "▶ Provisioning Demo 3 infrastructure…"
	@chmod +x scripts/setup-demo3.sh
	./scripts/setup-demo3.sh --infra-only

demo3-build:
	@echo "▶ Building Backstage image and pushing to ACR…"
	@chmod +x scripts/build-backstage.sh
	./scripts/build-backstage.sh

demo3-deploy:
	@echo "▶ Deploying Backstage to Container Apps…"
	@chmod +x scripts/deploy-backstage.sh
	./scripts/deploy-backstage.sh

demo3-verify:
	@echo "▶ Verifying Demo 3 deployment…"
	@chmod +x scripts/verify-demo3.sh
	./scripts/verify-demo3.sh

# ─── Local development ───────────────────────────────────────────────────────
local-api:
	@echo "▶ Starting .NET API on http://localhost:8080"
	cd apps/sample-dotnet-api/src && dotnet run

local-backstage:
	@echo "▶ Starting Backstage dev server (app: 3000, backend: 7007)"
	cd platform/backstage && yarn dev

# ─── Quality ─────────────────────────────────────────────────────────────────
test:
	@echo "▶ Running .NET tests"
	cd apps/sample-dotnet-api && \
	  dotnet test tests/sample-dotnet-api.Tests.csproj --configuration Release --logger "console;verbosity=normal"
	@echo "▶ Running Backstage tests"
	cd platform/backstage && yarn test:all

lint:
	@echo "▶ Linting Backstage TypeScript"
	cd platform/backstage && yarn lint

clean:
	@echo "▶ Cleaning build artifacts"
	cd apps/sample-dotnet-api && dotnet clean
	cd platform/backstage && yarn clean
