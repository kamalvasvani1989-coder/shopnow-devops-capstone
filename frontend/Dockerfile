# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit
COPY . .
# Served from the site root; API calls go to /api (proxied by nginx to backend-service)
ARG PUBLIC_URL=/
ARG REACT_APP_API_BASE_URL=/api
ENV PUBLIC_URL=$PUBLIC_URL REACT_APP_API_BASE_URL=$REACT_APP_API_BASE_URL
RUN npm run build

# Runtime stage
FROM nginx:1.27-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/health || exit 1
CMD ["nginx", "-g", "daemon off;"]
