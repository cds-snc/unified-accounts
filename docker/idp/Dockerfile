# The ECS task start command must change to `start-from-setup` when the version is updated
# For new environment creations, the command must be `start-from-init` with the `--steps` flag pointing to the steps.yaml file
FROM ghcr.io/zitadel/zitadel:v4.13.0@sha256:fbbe11f3ec190d7147e5e3d650f5d9aaeba822b1e6dcb63d9b946166c32b7c83

# Add custom configuration
COPY --chown=zitadel:zitadel ./*.yaml /app/
