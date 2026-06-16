#!/bin/bash
# Install BiocManager + Rgraphviz (Bioconductor) into .Library.
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

echo ">>> Installing BiocManager"
R -e "install.packages('BiocManager', lib=.Library); if (!requireNamespace('BiocManager', quietly=TRUE)) stop('Failed to install: BiocManager')"

echo ">>> Installing Rgraphviz (Bioconductor)"
R -e "BiocManager::install('Rgraphviz', lib=.Library); if (!requireNamespace('Rgraphviz', quietly=TRUE)) stop('Failed to install: Rgraphviz')"

echo ">>> Bioconductor installation complete"
