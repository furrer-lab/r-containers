#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# SPDX-FileCopyrightText: Copyright 2026 Jonas I. Liechti <j-i-l@t4d.ch>

# Install BiocManager + Rgraphviz (Bioconductor) into .Library.
#
# Requirements (must be set up by the Dockerfile before running this script):
#   - R is on PATH
#   - .Library is writable
#   - CRAN mirror is configured in Rprofile / Rprofile.site
#   - pak is installed and PKG_SYSREQS is enabled (the R-hub bases provide both)
set -e

echo ">>> Verifying .Library is writable"
R -e "if (file.access(.Library, 2) != 0) stop('.Library is not writable: ', .Library)"

echo ">>> Verifying CRAN mirror is configured"
R -e "if (is.null(getOption('repos')['CRAN']) || getOption('repos')['CRAN'] == '@CRAN@') stop('CRAN mirror not configured. Set it up in the Dockerfile before running this script.')"

echo ">>> Installing BiocManager and Rgraphviz"
R -e "pak::pkg_install(c('BiocManager', 'bioc::Rgraphviz'), lib=.Library); if (!requireNamespace('BiocManager', quietly=TRUE)) stop('Failed to install: BiocManager'); if (!requireNamespace('Rgraphviz', quietly=TRUE)) stop('Failed to install: Rgraphviz')"

echo ">>> Bioconductor installation complete"
