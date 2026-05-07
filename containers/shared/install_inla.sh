#!/bin/bash
# Install INLA into .Library, with stable -> testing fallback.
#
# The official INLA server (inla.r-inla-download.org) can be intermittently
# unreachable, so we try the testing repo as a fallback if stable fails.
#
# Requirements (must be set up by the Dockerfile before running this script):
#   - R is on PATH
#   - .Library is writable
#   - CRAN mirror is configured in Rprofile / Rprofile.site
set -e

echo ">>> Verifying .Library is writable"
R -e "if (file.access(.Library, 2) != 0) stop('.Library is not writable: ', .Library)"

echo ">>> Verifying CRAN mirror is configured"
R -e "if (is.null(getOption('repos')['CRAN']) || getOption('repos')['CRAN'] == '@CRAN@') stop('CRAN mirror not configured. Set it up in the Dockerfile before running this script.')"

echo ">>> Installing INLA"
R -e "\
repos_stable  <- c(getOption('repos'), INLA='https://inla.r-inla-download.org/R/stable'); \
repos_testing <- c(getOption('repos'), INLA='https://inla.r-inla-download.org/R/testing'); \
try_install <- function(repos, tag) { \
  message(sprintf('>>> Trying INLA from %s ...', tag)); \
  install.packages('INLA', lib=.Library, repos=repos, dep=TRUE); \
  if (!requireNamespace('INLA', quietly=TRUE)) stop('INLA not loadable') \
}; \
tryCatch(try_install(repos_stable, 'stable'), error = function(e1) { \
  try_install(repos_testing, 'testing') \
}); \
if (!requireNamespace('INLA', quietly=TRUE)) stop('Failed to install INLA from any source')"

echo ">>> INLA installation complete"
