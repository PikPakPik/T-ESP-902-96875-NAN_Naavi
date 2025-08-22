# Multi-stage build pour Angular SSR

# Stage 1: Build
FROM registry.gitlab.com/epitech-msc-2026/ci-factory/naavi-node22-pnpm-git-alpine:latest AS builder

WORKDIR /app

# Copier les fichiers de configuration pnpm
COPY package.json pnpm-lock.yaml ./
COPY nx.json ./
COPY tsconfig*.json ./

# Installer toutes les dépendances (dev + prod)
RUN pnpm install --frozen-lockfile

# Copier le code source
COPY . .

# Builder l'application Angular SSR
RUN pnpm nx build backoffice --prod

# Stage 2: Production runtime
FROM registry.gitlab.com/epitech-msc-2026/ci-factory/naavi-node22-pnpm-git-alpine:latest AS runtime

WORKDIR /app

# Copier seulement package.json et pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# Installer seulement les dépendances de production
RUN pnpm install --frozen-lockfile --prod

# Copier les fichiers buildés depuis le stage précédent
COPY --from=builder /app/dist ./dist

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=4200

# Exposer le port
EXPOSE 4200

# Sanity check (optionnel)
RUN ls -la dist/apps/

# Démarrer le serveur SSR
CMD ["node", "dist/apps/backoffice/server/server.mjs"]
