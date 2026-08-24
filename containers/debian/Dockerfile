# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: Copyright 2026 Jonas I. Liechti <j-i-l@t4d.ch>

# Final Debian image: R development tooling, glmmTMB workaround, target repo
# clone, and dependency scan.
#
# Built on top of the jags-inla-bioc layer. This is the only layer that touches the
# target repository, so it is the layer most likely to need rebuilding on
# every CI run; everything below it is heavily cached.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="R package development environment with resolved package dependencies." \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.authors="Jonas I. Liechti <j-i-l@t4d.ch>" \
      org.opencontainers.image.source="https://github.com/furrer-lab/r-containers" \
      org.opencontainers.image.documentation="https://github.com/furrer-lab/r-containers" \
      org.opencontainers.image.vendor="Furrer Lab"

LABEL org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.authors="Jonas I. Liechti <j-i-l@t4d.ch>"

# Build stage: ARGs need to be redeclared
ARG COMPILER
ARG PACKAGE_PATH
ARG REPO_PATH

# Run shared R tooling installation script (devtools, renv, covr, glmmTMB,
# clone target repo, install remaining dependencies, verify deps).
COPY shared/install_tooling.sh /tmp/install_tooling.sh
RUN chmod +x /tmp/install_tooling.sh && /tmp/install_tooling.sh

# Verify key packages are installed in .Library (fail the build if not)
RUN R -e "pkgs <- c('devtools','renv','covr','rjags','glmmTMB','INLA','Rgraphviz'); missing <- pkgs[!sapply(pkgs, requireNamespace, quietly=TRUE)]; if (length(missing)) stop('Packages missing from container: ', paste(missing, collapse=', '))"
