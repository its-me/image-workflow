FROM busybox:latest

ARG VERSION
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.source=https://github.com/its-me/image-workflow
LABEL org.opencontainers.image.title="workflow-single-stage"
LABEL org.opencontainers.image.description="Minimal image built from busybox in a single Dockerfile, demonstrating a standalone (non-chained) build"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Sergey Kanafyev <sergeykanafyev@gmail.com>"
