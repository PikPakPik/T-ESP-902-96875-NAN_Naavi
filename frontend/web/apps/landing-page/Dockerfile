# Multi-stage build pour Angular static

# Stage 1: Build
FROM registry.gitlab.com/epitech-msc-2026/naavi/ci-factory/naavi-node22-pnpm-git-alpine:latest AS builder

WORKDIR /app

# Copier les fichiers de configuration pnpm
COPY package.json pnpm-lock.yaml ./
COPY nx.json ./
COPY tsconfig*.json ./

# Installer toutes les dépendances (dev + prod)
RUN pnpm install --frozen-lockfile

# Copier le code source
COPY . .

# Builder l'application Angular statique
RUN pnpm nx build landing-page --prod

# Stage 2: Production runtime avec nginx
FROM nginx:alpine AS runtime

# Copier les fichiers statiques buildés depuis le stage précédent
COPY --from=builder /app/dist/apps/landing-page/browser /usr/share/nginx/html

# Créer une configuration nginx personnalisée pour SPA
RUN echo 'events {' > /etc/nginx/nginx.conf && \
    echo '    worker_connections 1024;' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf && \
    echo '' >> /etc/nginx/nginx.conf && \
    echo 'http {' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/mime.types;' >> /etc/nginx/nginx.conf && \
    echo '    default_type application/octet-stream;' >> /etc/nginx/nginx.conf && \
    echo '' >> /etc/nginx/nginx.conf && \
    echo '    sendfile on;' >> /etc/nginx/nginx.conf && \
    echo '    tcp_nopush on;' >> /etc/nginx/nginx.conf && \
    echo '    tcp_nodelay on;' >> /etc/nginx/nginx.conf && \
    echo '    keepalive_timeout 65;' >> /etc/nginx/nginx.conf && \
    echo '    types_hash_max_size 2048;' >> /etc/nginx/nginx.conf && \
    echo '' >> /etc/nginx/nginx.conf && \
    echo '    gzip on;' >> /etc/nginx/nginx.conf && \
    echo '    gzip_vary on;' >> /etc/nginx/nginx.conf && \
    echo '    gzip_min_length 1024;' >> /etc/nginx/nginx.conf && \
    echo '    gzip_proxied any;' >> /etc/nginx/nginx.conf && \
    echo '    gzip_comp_level 6;' >> /etc/nginx/nginx.conf && \
    echo '    gzip_types' >> /etc/nginx/nginx.conf && \
    echo '        text/plain' >> /etc/nginx/nginx.conf && \
    echo '        text/css' >> /etc/nginx/nginx.conf && \
    echo '        text/xml' >> /etc/nginx/nginx.conf && \
    echo '        text/javascript' >> /etc/nginx/nginx.conf && \
    echo '        application/javascript' >> /etc/nginx/nginx.conf && \
    echo '        application/xml+rss' >> /etc/nginx/nginx.conf && \
    echo '        application/json;' >> /etc/nginx/nginx.conf && \
    echo '' >> /etc/nginx/nginx.conf && \
    echo '    server {' >> /etc/nginx/nginx.conf && \
    echo '        listen 80;' >> /etc/nginx/nginx.conf && \
    echo '        server_name _;' >> /etc/nginx/nginx.conf && \
    echo '        root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf && \
    echo '        index index.html;' >> /etc/nginx/nginx.conf && \
    echo '' >> /etc/nginx/nginx.conf && \
    echo '        # Gestion des routes Angular (SPA)' >> /etc/nginx/nginx.conf && \
    echo '        location / {' >> /etc/nginx/nginx.conf && \
    echo '            try_files $uri $uri/ /index.html;' >> /etc/nginx/nginx.conf && \
    echo '        }' >> /etc/nginx/nginx.conf && \
    echo '' >> /etc/nginx/nginx.conf && \
    echo '        # Cache pour les assets' >> /etc/nginx/nginx.conf && \
    echo '        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {' >> /etc/nginx/nginx.conf && \
    echo '            expires 1y;' >> /etc/nginx/nginx.conf && \
    echo '            add_header Cache-Control "public, immutable";' >> /etc/nginx/nginx.conf && \
    echo '        }' >> /etc/nginx/nginx.conf && \
    echo '' >> /etc/nginx/nginx.conf && \
    echo '        # Sécurité' >> /etc/nginx/nginx.conf && \
    echo '        add_header X-Frame-Options DENY;' >> /etc/nginx/nginx.conf && \
    echo '        add_header X-Content-Type-Options nosniff;' >> /etc/nginx/nginx.conf && \
    echo '        add_header X-XSS-Protection "1; mode=block";' >> /etc/nginx/nginx.conf && \
    echo '    }' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf

# Exposer le port 80
EXPOSE 80

# Démarrer nginx
CMD ["nginx", "-g", "daemon off;"]
