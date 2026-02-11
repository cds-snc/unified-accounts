FROM ghcr.io/zitadel/zitadel:v4.10.1@sha256:13072d0eedb9f0d16df0fc4411e75da5abd7f9bf148c9e109a972463087a0b32

# Copy configuration and certificates
COPY --chown=zitadel:zitadel ./*.yaml ./certificate.crt ./private.key /app/
