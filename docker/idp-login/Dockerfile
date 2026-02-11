FROM ghcr.io/zitadel/zitadel-login:v4.10.1@sha256:becc59cc9fc242779e225737a6b7c9e34a6c09a217e8ccfe0031b42ae4d0e26c

USER root

RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

USER nextjs