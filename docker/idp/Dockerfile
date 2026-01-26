FROM ghcr.io/zitadel/zitadel:v4.9.1@sha256:2a7317d98b933cde3586c40b8dfc0a5f472174f78816095bded5107e646dfb25

# Copy configuration and certificates
COPY --chown=zitadel:zitadel ./*.yaml ./certificate.crt ./private.key /app/
