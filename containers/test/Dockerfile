# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: Copyright 2026 Jonas I. Liechti <j-i-l@t4d.ch>

FROM ghcr.io/r-hub/containers/ubuntu-release:latest

LABEL org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.authors="Jonas I. Liechti <j-i-l@t4d.ch>"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update --allow-releaseinfo-change -y && \
    apt-get upgrade -y
