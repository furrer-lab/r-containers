#!/bin/bash
# Install R development tooling, the glmmTMB workaround, then clone the
# target repository and install any remaining dependencies.
#
# Required environment variables:
#   REPO_PATH    - GitHub repo path (e.g. github.com/furrer-lab/abn)
#   PACKAGE_PATH - Path within the repo to the DESCRIPTION file (e.g. './')
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

# --- Helper: install a CRAN package into .Library and verify it loaded ---
install_r_pkg() {
  echo ">>> Installing R package: $1"
  R -e "install.packages('$1', lib=.Library); if (!requireNamespace('$1', quietly=TRUE)) stop('Failed to install: $1')"
}

# --- Development tooling ---
install_r_pkg devtools
install_r_pkg remotes
install_r_pkg R.rsp
install_r_pkg renv
install_r_pkg desc

# --- Vignette building ---
# rmarkdown >= 2.0 is required for modern pandoc citeproc support (built-in --citeproc)
install_r_pkg rmarkdown
install_r_pkg knitr

# --- Code coverage ---
install_r_pkg DT
install_r_pkg htmltools
install_r_pkg covr

# --- R CMD check helpers ---
install_r_pkg urlchecker

# --- glmmTMB workaround: needs explicit install before auto-dependency scan.
#     Should be installed automatically in the future. ---
install_r_pkg glmmTMB

# --- Clone target repo and install remaining dependencies ---
echo ">>> Cloning target repository"
cd /root/
git clone --depth=1 "https://${REPO_PATH}" target
cd target/

echo ">>> Installing remaining package dependencies"
R -e "package <- desc::desc()\$get_field('Package'); pckgs <- unique(renv::dependencies('${PACKAGE_PATH}')[,'Package']); pres_pckgs <- installed.packages()[,'Package']; missing <- pckgs[!(pckgs %in% pres_pckgs) & !(pckgs == package)]; if (length(missing) > 0) { cat('Installing:', paste(missing, collapse=', '), '\n'); install.packages(missing, lib=.Library) } else { cat('No additional dependencies to install.\n') }"

# --- Verify all dependencies installed ---
echo ">>> Verifying all dependencies are installed"
R -e "package <- desc::desc()\$get_field('Package'); pckgs <- unique(renv::dependencies('${PACKAGE_PATH}')[,'Package']); pres_pckgs <- installed.packages()[,'Package']; missing <- pckgs[!(pckgs %in% pres_pckgs) & !(pckgs == package)]; if (length(missing) > 0) { stop(paste0('Missing dependencies: ', paste(missing, collapse=', '))) } else { cat('All dependencies installed correctly.\n') }"

echo ">>> R tooling installation complete"
