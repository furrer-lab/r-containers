# Layer 5/5 (final): R development tooling, glmmTMB workaround, target repo
# clone, and dependency scan.
#
# Built on top of the bioc layer. This is the only layer that touches the
# target repository, so it is the layer most likely to need rebuilding on
# every CI run; everything below it is heavily cached.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

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
