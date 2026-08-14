FROM node:22-alpine@sha256:c610fcdfb1d5b4740dd70c284ed3cb16bb857e0f7166196e36a5501df7a3aa32 AS base
RUN apk add --no-cache ca-certificates openssl
WORKDIR /app

FROM base AS dependencies
COPY backend/content/package.json backend/content/package-lock.json ./
COPY backend/content/prisma ./prisma
RUN npm ci && npm run db:generate && npm prune --omit=dev && npm cache clean --force

FROM base AS runtime
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=8787 \
    CONTENT_PUBLIC_MODE=release \
    ALLOW_LEGACY_CONTENT_ADMIN=false
WORKDIR /app
COPY --chown=node:node --from=dependencies /app/node_modules ./node_modules
COPY --chown=node:node backend/content/package.json ./
COPY --chown=node:node backend/content/src ./src
COPY --chown=node:node assets/fonts/NotoSansEthiopic-Regular.ttf /assets/fonts/NotoSansEthiopic-Regular.ttf
USER node
EXPOSE 8787
CMD ["npm", "start"]
