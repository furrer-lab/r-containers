# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: Copyright 2026 Jonas I. Liechti <j-i-l@t4d.ch>

FROM ghcr.io/r-hub/containers/ubuntu-release:latest

LABEL org.opencontainers.image.description="Minimal R-hub Ubuntu image for container build tests." \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.authors="Jonas I. Liechti <j-i-l@t4d.ch>" \
      org.opencontainers.image.source="https://github.com/furrer-lab/r-containers" \
      org.opencontainers.image.documentation="https://github.com/furrer-lab/r-containers" \
      org.opencontainers.image.vendor="Furrer Lab"

LABEL org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.authors="Jonas I. Liechti <j-i-l@t4d.ch>"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update --allow-releaseinfo-change -y && \
    apt-get upgrade -y
