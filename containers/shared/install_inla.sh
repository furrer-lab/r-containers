#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: Copyright 2026 Jonas I. Liechti <j-i-l@t4d.ch>

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

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

install_inla_from_repo() {
  local repo_tag=$1
  local inla_repo="https://inla.r-inla-download.org/R/${repo_tag}/src/contrib"
  local inla_version

  echo ">>> Trying INLA from ${repo_tag} ..."
  inla_version=$(curl -fsSL -A "$USER_AGENT" "$inla_repo/PACKAGES" |
    awk '/^Package:/ {pkg=$2} pkg=="INLA" && /^Version:/ {print $2}' |
    sort -V | tail -n 1)

  if [ -z "$inla_version" ]; then
    echo "Failed to fetch INLA version from ${repo_tag}."
    return 1
  fi

  echo ">>> Found highest INLA version: ${inla_version} in ${repo_tag}. Downloading..."
  rm -f /tmp/INLA.tar.gz
  curl -fsSL -A "$USER_AGENT" -o /tmp/INLA.tar.gz \
    "$inla_repo/INLA_${inla_version}.tar.gz"

  if [ ! -s /tmp/INLA.tar.gz ]; then
    echo "Failed to download INLA tarball from ${repo_tag}."
    return 1
  fi

  echo ">>> Installing INLA and dependencies from local tarball..."
  Rscript --vanilla - <<'RSCRIPT'
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", lib = .Library,
                   repos = "https://cloud.r-project.org/")
}

remotes::install_local(
  "/tmp/INLA.tar.gz",
  lib = .Library,
  dependencies = NA,
  upgrade = "never",
  build = FALSE,
  repos = "https://cloud.r-project.org/"
)

if (!requireNamespace("INLA", quietly = TRUE)) {
  stop("INLA not loadable after local install")
}
RSCRIPT
}

if install_inla_from_repo stable; then
  echo ">>> INLA installed successfully from stable."
elif install_inla_from_repo testing; then
  echo ">>> INLA installed successfully from testing."
else
  echo "ERROR: Failed to install INLA from any source."
  exit 1
fi

echo ">>> INLA installation complete"
