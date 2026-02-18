FROM ghcr.io/zitadel/zitadel-login:v4.11.0@sha256:88b3597a6b43eb438667e2d55a5cc80ec391e47d22eef8442927f4658922b32f

USER root

RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

USER nextjs