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
set -euo pipefail

echo ">>> Verifying .Library is writable"
R -e "if (file.access(.Library, 2) != 0) stop('.Library is not writable: ', .Library)"

echo ">>> Verifying CRAN mirror is configured"
R -e "if (is.null(getOption('repos')['CRAN']) || getOption('repos')['CRAN'] == '@CRAN@') stop('CRAN mirror not configured. Set it up in the Dockerfile before running this script.')"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

install_inla_from_repo() {
  local repo_tag=$1
  local inla_repo="https://inla.r-inla-download.org/R/${repo_tag}/src/contrib"
  local inla_version
  local packages_file

  echo ">>> Trying INLA from ${repo_tag} ..."
  packages_file=$(mktemp)
  if ! curl -fsSL \
    --retry 5 \
    --retry-delay 2 \
    --retry-all-errors \
    --connect-timeout 30 \
    --max-time 120 \
    -A "$USER_AGENT" \
    -o "$packages_file" \
    "$inla_repo/PACKAGES"; then
    echo "Failed to fetch the INLA package index from ${repo_tag}."
    rm -f "$packages_file"
    return 1
  fi

  inla_version=$(awk '/^Package:/ {pkg=$2} pkg=="INLA" && /^Version:/ {print $2}' \
    "$packages_file" | sort -V | tail -n 1)
  rm -f "$packages_file"

  if [ -z "$inla_version" ]; then
    echo "INLA package index from ${repo_tag} did not contain a version."
    return 1
  fi

  echo ">>> Found highest INLA version: ${inla_version} in ${repo_tag}. Downloading..."
  rm -f /tmp/INLA.tar.gz
  if ! curl -fsSL \
    --retry 5 \
    --retry-delay 2 \
    --retry-all-errors \
    --connect-timeout 30 \
    --max-time 300 \
    -A "$USER_AGENT" \
    -o /tmp/INLA.tar.gz \
    "$inla_repo/INLA_${inla_version}.tar.gz"; then
    echo "Failed to download INLA ${inla_version} from ${repo_tag}."
    rm -f /tmp/INLA.tar.gz
    return 1
  fi

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

repos <- c(
  CRAN = "https://cloud.r-project.org/",
  INLA = "https://inlabru-org.r-universe.dev/"
)

inla_dir <- tempfile("INLA-")
dir.create(inla_dir)
on.exit(unlink(inla_dir, recursive = TRUE), add = TRUE)
utils::untar("/tmp/INLA.tar.gz", exdir = inla_dir)

# rlang >= 1.2.0 uses R_envSymbols(), which is not available in the
# R-devel snapshot used by the Fedora images. Install the last compatible
# release first so dependency resolution does not select the broken version.
if (grepl("Under development", R.version$status, fixed = TRUE)) {
  message(">>> Pinning rlang to 1.1.7 for R-devel")
  remotes::install_version(
    "rlang",
    version = "1.1.7",
    lib = .Library,
    upgrade = "never",
    repos = repos
  )
}

message(">>> Installing INLA dependency chain")
remotes::install_deps(
  file.path(inla_dir, "INLA"),
  dependencies = NA,
  upgrade = "never",
  lib = .Library,
  repos = repos
)

message(">>> Installing INLA without re-resolving dependencies")
remotes::install_local(
  "/tmp/INLA.tar.gz",
  lib = .Library,
  dependencies = FALSE,
  upgrade = "never",
  build = FALSE,
  repos = repos
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
