# Before the build stage
ARG COMPILER
ARG R_VERSION
ARG RHUB_IMAGE=valgrind

# The valgrind container is Fedora-based with gcc and R-devel
# see https://r-hub.github.io/containers/containers.html#valgrind
FROM rhub/${RHUB_IMAGE}

# Build stage: ARGs need to be redeclared
ARG COMPILER
ARG R_VERSION
ARG PACKAGE_PATH
ARG REPO_PATH
ARG JAGS
ARG DRMEMORY

# Install ALL system dependencies in one layer
RUN dnf -y upgrade
RUN dnf -y install \
  # Core build tools
  cmake \
  git \
  openssh-clients \
  pkgconf \
  # SSL / curl
  openssl-devel \
  libcurl-devel \
  # libuv (fs R package)
  libuv-devel \
  # Text / font rendering
  fontconfig-devel \
  harfbuzz-devel \
  fribidi-devel \
  freetype-devel \
  # Image formats
  libpng-devel \
  libtiff-devel \
  libjpeg-devel \
  libwebp-devel \
  # XML
  libxml2-devel \
  # GSL (gsl R package)
  gsl-devel \
  # SQLite
  sqlite-devel \
  # NLopt (nloptr / lme4)
  NLopt-devel \
  # JAGS build deps + BLAS/LAPACK
  lapack* blas* atlas* flexiblas-devel \
  # s2 (INLA dependency chain)
  abseil-cpp-devel \
  # sf / fmesher (INLA dependency chain)
  udunits2-devel \
  gdal-devel \
  geos-devel \
  proj-devel \
  # Magick++ (magick R package)
  ImageMagick-c++-devel \
  # Pandoc (vignette building)
  pandoc

# Install DrMemory
RUN dnf -y install libunwind
ADD https://github.com/DynamoRIO/drmemory/releases/download/release_$DRMEMORY/DrMemory-Linux-$DRMEMORY.tar.gz /tmp/drmemory.tar.gz
RUN mkdir -p /opt/DrMemory \
    && tar -xf /tmp/drmemory.tar.gz --directory /opt/DrMemory \
    && rm /tmp/drmemory.tar.gz \
    && chmod 755 /opt/DrMemory/DrMemory-Linux-$DRMEMORY/bin/drmemory
ENV PATH="/opt/DrMemory/DrMemory-Linux-$DRMEMORY/bin:${PATH}"

# Add R to PATH (valgrind R is installed at a fixed path)
ENV PATH="/opt/R/devel-valgrind/bin:${PATH}"

# Force all R package installs into .Library (the base R library directory).
# This ensures packages are visible to all users, not just root.
# R_LIBS_USER=" " (single space) is the canonical way to disable the user
# library fallback that would otherwise install into /root/R/...
ENV R_LIBS_USER=" "
# Prevent renv auto-activation when cloning repos that contain .Rprofile
ENV RENV_CONFIG_AUTOLOADER_ENABLED=false

# Set CRAN mirror (must happen before any R package installs)
RUN R_HOME=$(R RHOME) && \
    if [ -d "${R_HOME}/library/base/R" ]; then \
      echo 'options(repos = c(CRAN = "https://cran.rstudio.com"))' >> ${R_HOME}/library/base/R/Rprofile; \
    elif [ -d "${R_HOME}/etc" ]; then \
      echo 'options(repos = c(CRAN = "https://cran.rstudio.com"))' >> ${R_HOME}/etc/Rprofile.site; \
    else \
      echo "ERROR: Could not find R profile location" >&2; exit 1; \
    fi

# Build and install JAGS from source
# See https://usermanual.wiki/Document/jagsinstallationmanual.880863585.pdf
ADD https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/$JAGS.tar.gz/download /tmp/jags.tar.gz
WORKDIR /tmp/
RUN tar -xf jags.tar.gz && rm jags.tar.gz
WORKDIR /tmp/$JAGS
RUN if [ "$COMPILER" = "clang" ]; then \
      RCC=/usr/bin/clang RCXX="/usr/bin/clang++ -std=gnu++17 -stdlib=libc++"; \
    else \
      RCC=/usr/bin/gcc RCXX="/usr/bin/g++"; \
    fi \
    && LD="llvm-ld" CC="${RCC}" CXX="${RCXX}" \
       ./configure \
         --with-blas="-L/opt/R/devel-valgrind/lib/R/lib -lRblas" \
         --with-lapack="-L/opt/R/devel-valgrind/lib/R/lib -lRlapack" \
         --libdir=/usr/local/lib \
    && make && make install
# JAGS shared libs are in /usr/local/lib — make sure the linker finds them
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# Install rjags (needs --enable-rpath to find JAGS shared libs)
RUN R -e "install.packages('rjags', lib=.Library, configure.args = '--enable-rpath'); if (!requireNamespace('rjags', quietly=TRUE)) stop('Failed to install: rjags')"

# Run shared R package installation script
COPY shared/install_r_packages.sh /tmp/install_r_packages.sh
RUN chmod +x /tmp/install_r_packages.sh && /tmp/install_r_packages.sh

# Verify key packages are installed in .Library (fail the build if not)
RUN R -e "pkgs <- c('devtools','renv','covr','rjags','INLA','Rgraphviz'); missing <- pkgs[!sapply(pkgs, requireNamespace, quietly=TRUE)]; if (length(missing)) stop('Packages missing from container: ', paste(missing, collapse=', '))"
