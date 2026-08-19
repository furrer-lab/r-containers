#!/bin/bash
# Shared R package installation script for all container variants.
# This script is COPY'd into each container and run after all OS-specific
# system packages and libraries (JAGS, etc.) are already installed.
#
# Required environment variables:
#   REPO_PATH    - GitHub repo path (e.g. github.com/furrer-lab/abn)
#   PACKAGE_PATH - Path within the repo to the DESCRIPTION file (e.g. './')
#
# All packages are installed into .Library (the base R library directory)
# so they are visible to every user, not just root. This is critical because
# CI jobs run with --user 1001, which cannot see root's personal library at
# /root/R/x86_64-pc-linux-gnu-library/.
set -e

# --- Verify .Library is writable ---
R -e "if (file.access(.Library, 2) != 0) stop('.Library is not writable: ', .Library)"

# --- Helper: install a CRAN package into .Library and verify it loaded ---
install_r_pkg() {
  echo ">>> Installing R package: $1"
  R -e "install.packages('$1', lib=.Library); if (!requireNamespace('$1', quietly=TRUE)) stop('Failed to install: $1')"
}

# --- Verify CRAN mirror is configured (must be set up in Dockerfile before this script) ---
R -e "if (is.null(getOption('repos')['CRAN']) || getOption('repos')['CRAN'] == '@CRAN@') stop('CRAN mirror not configured. Set it up in the Dockerfile before running this script.')"

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

# --- Bioconductor ---
install_r_pkg BiocManager
echo ">>> Installing Rgraphviz (Bioconductor)"
R -e "BiocManager::install('Rgraphviz', lib=.Library); if (!requireNamespace('Rgraphviz', quietly=TRUE)) stop('Failed to install: Rgraphviz')"

# --- INLA (non-CRAN repository) ---
# Two-tier fallback: stable -> testing.
#
# The official INLA server (inla.r-inla-download.org) can be intermittently
# unreachable, so we try the testing repo as a fallback.
echo ">>> Bypassing WAF: Resolving latest INLA version via curl..."
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

install_inla_from_repo() {
    local REPO_TAG=$1
    echo ">>> Trying INLA from ${REPO_TAG} ..."
    local INLA_REPO="https://inla.r-inla-download.org/R/${REPO_TAG}/src/contrib"
    
    # 1. Fetch all versions, sort, and pick the highest
    local INLA_VERSION=$(curl -s -L -A "$USER_AGENT" "$INLA_REPO/PACKAGES" | awk '/^Package:/ {pkg=$2} pkg=="INLA" && /^Version:/ {print $2}' | sort -V | tail -n 1)
    
    if [ -z "$INLA_VERSION" ]; then
        echo "Failed to fetch INLA version from ${REPO_TAG}."
        return 1
    fi
    
    echo ">>> Found highest INLA version: ${INLA_VERSION} in ${REPO_TAG}. Downloading..."
    
    # 2. Download the tarball directly to /tmp
    curl -s -L -A "$USER_AGENT" -o /tmp/INLA.tar.gz "$INLA_REPO/INLA_${INLA_VERSION}.tar.gz"
    
    if [ ! -s /tmp/INLA.tar.gz ]; then
        echo "Failed to download INLA tarball from ${REPO_TAG}."
        return 1
    fi
    
    echo ">>> Handing local tarball to R for installation..."
    
    # 3. Install the local tarball using R. Use a heredoc instead of R -e:
    # shell processing of escaped newlines can concatenate R expressions.
    Rscript --vanilla - <<'RSCRIPT'
if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes", repos = "https://cloud.r-project.org/")
}
message(">>> Installing INLA and dependencies...")
tryCatch({
    remotes::install_local(
        "/tmp/INLA.tar.gz",
        dependencies = TRUE,
        upgrade = "never",
        repos = "https://cloud.r-project.org/"
    )
}, error = function(e) {
    stop(paste("Error during INLA installation:", e$message))
})
if (!requireNamespace("INLA", quietly = TRUE)) {
    stop("INLA not loadable after local install")
}
RSCRIPT
    
    return $?
}

if install_inla_from_repo "stable"; then
    echo ">>> INLA installed successfully from stable."
else
    echo ">>> Stable failed. Falling back to testing..."
    if install_inla_from_repo "testing"; then
        echo ">>> INLA installed successfully from testing."
    else
        echo "ERROR: Failed to install INLA from any source."
        exit 1
    fi
fi

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

echo ">>> R package installation complete"
