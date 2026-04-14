# Before the build stage
ARG COMPILER
ARG R_VERSION
ARG RHUB_IMAGE=ubuntu-clang

# Use the mapped R-hub image name from the workflow
FROM rhub/${RHUB_IMAGE}

# Build stage: ARGs need to be redeclared
ARG COMPILER
ARG R_VERSION
ARG PACKAGE_PATH
ARG REPO_PATH

# Install ALL system dependencies in one layer
RUN apt-get update --allow-releaseinfo-change && apt-get install -y --no-install-recommends \
  # Core build tools
  gfortran \
  cmake \
  git \
  openssh-client \
  pkg-config \
  # SSL / curl
  libssl-dev \
  libcurl4-openssl-dev \
  # Text / font rendering (ragg, systemfonts, textshaping)
  libfontconfig1-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libfreetype6-dev \
  # Image formats
  libpng-dev \
  libtiff5-dev \
  libjpeg-dev \
  libwebp-dev \
  # XML
  libxml2-dev \
  # GSL (gsl R package)
  libgsl-dev \
  # NLopt (nloptr / lme4)
  libnlopt-dev \
  # JAGS (rjags)
  jags \
  # s2 (INLA dependency chain)
  libabsl-dev \
  # sf / fmesher (INLA dependency chain)
  libudunits2-dev \
  libgdal-dev \
  libgeos-dev \
  libproj-dev \
  # Magick++ (magick R package)
  libmagick++-dev

# Add R to PATH
ENV PATH="/opt/R-$R_VERSION/bin:${PATH}"

# Configure clang C++ compilation environment
ENV CPLUS_INCLUDE_PATH="/usr/include/c++/13:/usr/include/x86_64-linux-gnu/c++/13"
ENV C_INCLUDE_PATH="/usr/include"

# Set CRAN mirror (must happen before any R package installs)
RUN R_HOME=$(R RHOME) && \
    if [ -d "${R_HOME}/library/base/R" ]; then \
      echo 'options(repos = c(CRAN = "https://cran.rstudio.com"))' >> ${R_HOME}/library/base/R/Rprofile; \
    elif [ -d "${R_HOME}/etc" ]; then \
      echo 'options(repos = c(CRAN = "https://cran.rstudio.com"))' >> ${R_HOME}/etc/Rprofile.site; \
    else \
      echo "ERROR: Could not find R profile location" >&2; exit 1; \
    fi

# Install rjags (JAGS is available as system package on debian)
RUN R -e "install.packages('rjags'); if (!requireNamespace('rjags', quietly=TRUE)) stop('Failed to install: rjags')"

# glmmTMB workaround: needs explicit install before auto-dependency scan.
# Should be installed automatically in the future.
RUN R -e "install.packages('glmmTMB'); if (!requireNamespace('glmmTMB', quietly=TRUE)) stop('Failed to install: glmmTMB')"

# Run shared R package installation script
COPY shared/install_r_packages.sh /tmp/install_r_packages.sh
RUN chmod +x /tmp/install_r_packages.sh && /tmp/install_r_packages.sh
