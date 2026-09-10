# syntax=docker/dockerfile:1.7

FROM node:24-bookworm-slim AS base

ARG NPM_REGISTRY=https://package-mirror.liara.ir/repository/npm/
ARG PNPM_VERSION=10.11.1

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
ENV NPM_CONFIG_REGISTRY=$NPM_REGISTRY

RUN npm install --global "pnpm@$PNPM_VERSION" \
  && test "$(pnpm --version)" = "$PNPM_VERSION"

WORKDIR /server


FROM base AS dependencies

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json .npmrc ./
COPY apps/backend/package.json ./apps/backend/package.json
COPY apps/storefront/package.json ./apps/storefront/package.json

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
  pnpm install --frozen-lockfile


FROM dependencies AS backend-builder

ARG MEDUSA_BACKEND_URL=https://api.shop.web-father.ir
ARG MEDUSA_STOREFRONT_URL=https://shop.web-father.ir

ENV MEDUSA_BACKEND_URL=$MEDUSA_BACKEND_URL
ENV MEDUSA_STOREFRONT_URL=$MEDUSA_STOREFRONT_URL

COPY apps/backend ./apps/backend
COPY eslint.config.ts ./eslint.config.ts

# Medusa evaluates its configuration while compiling the Admin. These values
# are non-secret build placeholders; Dokploy supplies all real runtime secrets.
RUN DATABASE_URL=postgres://medusa:build-only@127.0.0.1:5432/medusa \
  REDIS_URL=redis://127.0.0.1:6379 \
  CACHE_REDIS_URL=redis://127.0.0.1:6379 \
  LOCKING_REDIS_URL=redis://127.0.0.1:6379 \
  STORE_CORS=$MEDUSA_STOREFRONT_URL \
  ADMIN_CORS=$MEDUSA_BACKEND_URL \
  AUTH_CORS=$MEDUSA_STOREFRONT_URL,$MEDUSA_BACKEND_URL \
  JWT_SECRET=build-only-not-used-at-runtime \
  COOKIE_SECRET=build-only-not-used-at-runtime \
  FILE_PROVIDER=local \
  pnpm --filter @dtc/backend build

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
  pnpm --dir apps/backend/.medusa/server install \
    --prod \
    --ignore-workspace \
    --no-frozen-lockfile


FROM base AS backend

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=9000

WORKDIR /server

COPY --from=backend-builder --chown=node:node \
  /server/apps/backend/.medusa/server ./

RUN mkdir -p /server/static \
  && chown node:node /server/static

USER node

EXPOSE 9000

CMD ["pnpm", "start"]


FROM dependencies AS storefront-builder

ARG NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
ARG NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.shop.web-father.ir
ARG NEXT_PUBLIC_BASE_URL=https://shop.web-father.ir
ARG NEXT_PUBLIC_DEFAULT_REGION=dk
ARG NEXT_PUBLIC_STRIPE_KEY
ARG NEXT_PUBLIC_MEDUSA_PAYMENTS_PUBLISHABLE_KEY
ARG NEXT_PUBLIC_MEDUSA_PAYMENTS_ACCOUNT_ID
ARG S3_FILE_URL
ARG MEDUSA_CLOUD_S3_HOSTNAME
ARG MEDUSA_CLOUD_S3_PATHNAME

ENV NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=$NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_MEDUSA_BACKEND_URL=$NEXT_PUBLIC_MEDUSA_BACKEND_URL
ENV NEXT_PUBLIC_BASE_URL=$NEXT_PUBLIC_BASE_URL
ENV NEXT_PUBLIC_DEFAULT_REGION=$NEXT_PUBLIC_DEFAULT_REGION
ENV NEXT_PUBLIC_STRIPE_KEY=$NEXT_PUBLIC_STRIPE_KEY
ENV NEXT_PUBLIC_MEDUSA_PAYMENTS_PUBLISHABLE_KEY=$NEXT_PUBLIC_MEDUSA_PAYMENTS_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_MEDUSA_PAYMENTS_ACCOUNT_ID=$NEXT_PUBLIC_MEDUSA_PAYMENTS_ACCOUNT_ID
ENV S3_FILE_URL=$S3_FILE_URL
ENV MEDUSA_CLOUD_S3_HOSTNAME=$MEDUSA_CLOUD_S3_HOSTNAME
ENV MEDUSA_CLOUD_S3_PATHNAME=$MEDUSA_CLOUD_S3_PATHNAME

COPY apps/storefront ./apps/storefront

RUN pnpm --filter @dtc/storefront build


FROM node:24-bookworm-slim AS storefront

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=8000

WORKDIR /server

COPY --from=storefront-builder --chown=node:node \
  /server/apps/storefront/.next/standalone ./
COPY --from=storefront-builder --chown=node:node \
  /server/apps/storefront/.next/static ./apps/storefront/.next/static
COPY --from=storefront-builder --chown=node:node \
  /server/apps/storefront/public ./apps/storefront/public

USER node

EXPOSE 8000

CMD ["node", "apps/storefront/server.js"]
