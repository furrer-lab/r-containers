#!/bin/bash
# Shared R package installation script for all container variants.
# This script is COPY'd into each container and run after all OS-specific
# system packages and libraries (JAGS, etc.) are already installed.
#
# Required environment variables:
#   REPO_PATH    - GitHub repo path (e.g. github.com/furrer-lab/abn)
#   PACKAGE_PATH - Path within the repo to the DESCRIPTION file (e.g. './')
set -e

# --- Helper: install a CRAN package and verify it loaded ---
install_r_pkg() {
  echo ">>> Installing R package: $1"
  R -e "install.packages('$1'); if (!requireNamespace('$1', quietly=TRUE)) stop('Failed to install: $1')"
}

# --- Set CRAN mirror (works on all R-hub base images) ---
R_HOME=$(R RHOME)
if [ -d "${R_HOME}/library/base/R" ]; then
  echo 'options(repos = c(CRAN = "https://cran.rstudio.com"))' >> "${R_HOME}/library/base/R/Rprofile"
elif [ -d "${R_HOME}/etc" ]; then
  echo 'options(repos = c(CRAN = "https://cran.rstudio.com"))' >> "${R_HOME}/etc/Rprofile.site"
else
  echo "ERROR: Could not find R profile location" >&2
  exit 1
fi

# --- Development tooling ---
install_r_pkg devtools
install_r_pkg remotes
install_r_pkg R.rsp
install_r_pkg renv
install_r_pkg desc

# --- Code coverage ---
install_r_pkg DT
install_r_pkg htmltools
install_r_pkg covr

# --- R CMD check helpers ---
install_r_pkg urlchecker

# --- Bioconductor ---
install_r_pkg BiocManager
echo ">>> Installing Rgraphviz (Bioconductor)"
R -e "BiocManager::install('Rgraphviz'); if (!requireNamespace('Rgraphviz', quietly=TRUE)) stop('Failed to install: Rgraphviz')"

# --- INLA (non-CRAN repository) ---
echo ">>> Installing INLA"
R -e "install.packages('INLA', repos=c(getOption('repos'), INLA='https://inla.r-inla-download.org/R/stable'), dep=TRUE); if (!requireNamespace('INLA', quietly=TRUE)) stop('Failed to install: INLA')"

# --- Clone target repo and install remaining dependencies ---
echo ">>> Cloning target repository"
cd /root/
git clone --depth=1 "https://${REPO_PATH}" target
cd target/

echo ">>> Installing remaining package dependencies"
R -e "renv::deactivate()"
R -e "package <- desc::desc()\$get_field('Package'); pckgs <- unique(renv::dependencies('${PACKAGE_PATH}')[,'Package']); pres_pckgs <- installed.packages()[,'Package']; missing <- pckgs[!(pckgs %in% pres_pckgs) & !(pckgs == package)]; if (length(missing) > 0) { cat('Installing:', paste(missing, collapse=', '), '\n'); install.packages(missing) } else { cat('No additional dependencies to install.\n') }"

# --- Verify all dependencies installed ---
echo ">>> Verifying all dependencies are installed"
R -e "renv::deactivate()"
R -e "package <- desc::desc()\$get_field('Package'); pckgs <- unique(renv::dependencies('${PACKAGE_PATH}')[,'Package']); pres_pckgs <- installed.packages()[,'Package']; missing <- pckgs[!(pckgs %in% pres_pckgs) & !(pckgs == package)]; if (length(missing) > 0) { stop(paste0('Missing dependencies: ', paste(missing, collapse=', '))) } else { cat('All dependencies installed correctly.\n') }"

echo ">>> R package installation complete"
