# syntax=docker/dockerfile:1.6
# Multi-stage Backstage build — context must be the repository root so that
# catalog/ is available inside the image.

# ─── Stage 1: extract package.json files for layer-cache efficiency ──────────
FROM node:20-bookworm-slim AS packages

WORKDIR /app

COPY platform/backstage/package.json platform/backstage/yarn.lock ./
COPY platform/backstage/packages/app/package.json    packages/app/package.json
COPY platform/backstage/packages/backend/package.json packages/backend/package.json
COPY platform/backstage/plugins/cost-widget/package.json plugins/cost-widget/package.json

# ─── Stage 2: install all deps & build ───────────────────────────────────────
FROM node:20-bookworm-slim AS build

# Build tools required by some native addons
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=development

WORKDIR /app

# Restore deps from cached package layer
COPY --from=packages /app/package.json /app/yarn.lock ./
COPY --from=packages /app/packages ./packages
COPY --from=packages /app/plugins  ./plugins

RUN yarn install --frozen-lockfile --network-timeout 600000 --prefer-offline

# Copy all source
COPY platform/backstage/tsconfig.json ./tsconfig.json
COPY platform/backstage/packages     ./packages
COPY platform/backstage/plugins      ./plugins
COPY platform/backstage/app-config   ./app-config
COPY platform/backstage/templates    ./templates

# Copy catalog data so the file-based catalog works inside the container
COPY catalog ./catalog

# Type-check the whole workspace
RUN yarn tsc

# Build the frontend (writes to packages/app/dist)
RUN yarn workspace app build

# Build the backend bundle (writes packages/backend/dist/bundle.tar.gz)
RUN yarn workspace backend build

# ─── Stage 3: production image ───────────────────────────────────────────────
FROM node:20-bookworm-slim AS production

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
  && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production

WORKDIR /app

# Minimal workspace skeleton needed for production yarn install
COPY --from=build /app/yarn.lock      ./yarn.lock
COPY --from=build /app/package.json   ./package.json
COPY --from=build /app/packages/backend/package.json ./packages/backend/package.json

# Extract the backend bundle
COPY --from=build /app/packages/backend/dist/bundle.tar.gz ./bundle.tar.gz
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Install only production dependencies
RUN yarn install \
    --frozen-lockfile \
    --production \
    --network-timeout 600000 \
    --ignore-scripts \
    --prefer-offline

# Embed the pre-built frontend as backend static files
COPY --from=build /app/packages/app/dist \
     ./packages/backend/dist/static

# Copy config, catalog, and scaffolder templates into the runtime image
COPY --from=build /app/app-config  ./app-config
COPY --from=build /app/catalog     ./catalog
COPY --from=build /app/templates   ./templates

# Non-root user
USER node

EXPOSE 7007

CMD ["node", \
     "packages/backend", \
     "--config", "app-config/app-config.yaml", \
     "--config", "app-config/app-config.production.yaml"]
