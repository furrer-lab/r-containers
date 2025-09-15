# Before the build stage
ARG TARGET_OS
ARG COMPILER
ARG R_VERSION
ARG RHUB_IMAGE=ubuntu-gcc12

# Use the mapped R-hub image name from the workflow
FROM rhub/${RHUB_IMAGE}

# Build stage: ARGs need to be redeclared
ARG TARGET_OS
ARG COMPILER
ARG R_VERSION
# ARG PACKAGE
ARG PACKAGE_PATH
ARG REPO_PATH
ARG JAGS
# # sets the date for the CRAN snapshot (e.g. BUILD_DATE=2023-12-20)
# ARG BUILD_DATE

# Update package repositories
RUN dnf check-update && dnf -y install \
  openssl-devel \
  libcurl-devel \
  fontconfig-devel \
  libxml2-devel \
  harfbuzz-devel \
  fribidi-devel \
  freetype-devel \
  libpng-devel \
  libtiff-devel \
  libjpeg-devel \
  libwebp-devel

# add R to PATH
ENV PATH="/opt/R-$R_VERSION/bin:${PATH}"

# diff to debian: /lib/ > /lib64/
# ENV PATH "$PATH:/opt/R-devel/bin/"
# Find where R is installed and set the CRAN repository
RUN R_HOME=$(R RHOME) && \
    if [ -d "${R_HOME}/library/base/R" ]; then \
      echo 'options(repos =c(CRAN = "https://cran.rstudio.com"))' >> ${R_HOME}/library/base/R/Rprofile; \
    elif [ -d "${R_HOME}/etc" ]; then \
      echo 'options(repos =c(CRAN = "https://cran.rstudio.com"))' >> ${R_HOME}/etc/Rprofile.site; \
    else \
      echo "Warning: Could not find R profile location, skipping CRAN mirror setup"; \
    fi

# rjags:
RUN dnf -y install \
  lapack* blas* atlas* 
ADD https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/$JAGS.tar.gz/download /tmp/jags.tar.gz
WORKDIR /tmp/
RUN ls /tmp/
RUN tar -xf jags.tar.gz
WORKDIR /tmp/$JAGS
# Building JAGS requires the same environment that is then used to build rjags.
# To achieve this we follow the approach for building JAGS with Clang outlined
# in the JAGS installation guide
# (https://usermanual.wiki/Document/jagsinstallationmanual.880863585.pdf)
# and substitute the compilers with the specifics from the R installation that
# we can get by using the `R CMD config CC/CXX/BLAS_LIBS/LAPACK_LIBS' commands:
RUN if [ "$COMPILER" = "clang" ]; then RCC=/usr/bin/clang RCXX="/usr/bin/clang++ -std=gnu++17 -stdlib=libc++"; else RRCC=/usr/bin/gcc RCXX="/usr/bin/g++"; fi \
    && LD="llvm-ld" CC="${RCC}" CXX="${RCXX}" ./configure --with-blas="-L/opt/R-devel/lib64/R/lib -lRblas" --with-lapack="-L/opt/R-devel/lib64/R/lib -lRlapack" --libdir=/usr/local/lib64 && make && make install
RUN ls /tmp/$JAGS
# ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
# RUN R -e "install.packages('rjags')"
RUN R -e "install.packages('rjags', configure.args = '--enable-rpath')"

# Get and install packages for local debugging
RUN R -e "install.packages('devtools')" \
 && R -e "install.packages('remotes')" \
 && R -e "install.packages('R.rsp')" \
 && R -e "install.packages('renv')" \
 && R -e "install.packages('desc')"
# For code coverage
RUN R -e "install.packages('DT')" \
 && R -e "install.packages('htmltools')" \
 && R -e "install.packages('covr')"

# Prepare for potential check to be run
RUN R -e "install.packages('urlchecker')"

# Install dependencies not managed by CRAN
# - lme4 and gsl:
RUN dnf -y install \
      gsl-devel \
      sqlite-devel \
      NLopt-devel
# RUN R -e "install.packages('lme4')"
# RUN R -e "install.packages('gsl')"

# Graphviz
RUN R -e "install.packages('BiocManager')" \
 && R -e "BiocManager::install('Rgraphviz')"

# INLA
# - s2
RUN dnf -y install \
      abseil-cpp-devel
# - sf
RUN dnf -y install \
  udunits2-devel gdal-devel geos-devel proj-devel
# RUN R -e "install.packages('sf')"
# - fmesher
RUN dnf -y install \
      udunits2-devel
# RUN R -e "install.packages('fmesher')"
# - INLA
RUN R -e "install.packages('INLA',repos=c(getOption('repos'),INLA='https://inla.r-inla-download.org/R/stable'), dep=TRUE)"
# - Magick++
RUN dnf -y install \
      ImageMagick-c++-devel

###
# install all package dependencies
###
RUN dnf -y install \
      git \
      openssh-clients \
      gcc-gfortran
WORKDIR /root/
# get a shallow copy of the target repository
# # Note: If the repository is private you must use a deploy token here (ssh key) 
# RUN --mount=type=secret,id=key,dst=/root/.ssh/key GIT_SSH_COMMAND="ssh -i /root/.ssh/key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone --depth=1 git@$REPO_PATH target
RUN git clone --depth=1 https://$REPO_PATH target
WORKDIR target/
# get a list of all dependencies; install remaining packages
# escape=\
# Install all dependencies of PACKAGE_NAME but not the package it self
RUN R -e "renv::deactivate()"
RUN R -e "desc::desc()\$get_field('Package')"
RUN R -e "unique(renv::dependencies('$PACKAGE_PATH')[,'Package'])"
RUN R -e "installed.packages()[,'Package']"
RUN R -e "package<-desc::desc()\$get_field('Package');pckgs<-unique(renv::dependencies('$PACKAGE_PATH')[,'Package']);pres_pckgs<-installed.packages()[,'Package'];install.packages(pckgs[!(pckgs %in% pres_pckgs) & !(pckgs == package)])"
