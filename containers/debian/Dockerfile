# Before the build stage
ARG TARGET_OS
ARG COMPILER
ARG R_VERSION

FROM rhub/${TARGET_OS}-${COMPILER}-${R_VERSION}

# Build stage: ARGs need to be redeclared
ARG TARGET_OS
ARG COMPILER
ARG R_VERSION
# ARG PACKAGE
ARG PACKAGE_PATH
ARG REPO_PATH
# # sets the date for the CRAN snapshot (e.g. BUILD_DATE=2023-12-20)
# ARG BUILD_DATE

# Unsure why this is needed as openssl seems to be installed already
RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl-dev \
  libcurl4-openssl-dev \
  gfortran

# add R to PATH
# NOTE: For R-release this is not needed
ENV PATH="/opt/R-$R_VERSION/bin:${PATH}"

# ENV PATH "$PATH:/opt/R-devel/bin/"
# Set a mirror for CRAN
RUN if [ "$R_VERSION" = "release" ]; then RPATH=""; else RPATH=/opt/R-$R_VERSION; fi \
    && echo 'options(repos =c(CRAN = "https://cran.rstudio.com"))' >> ${RPATH}/lib/R/library/base/R/Rprofile

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
# lme4:
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgsl-dev \
      libnlopt-dev
# RUN R -e "install.packages('lme4')"
# rjags:
RUN apt-get update && apt-get install -y --no-install-recommends \
      jags \
      git \
      openssh-client

# RUN R -e "install.packages('rjags')"
# Graphviz
RUN R -e "install.packages('BiocManager')" \
 && R -e "BiocManager::install('Rgraphviz')"
# INLA
# - s2
RUN apt-get update && apt-get install -y --no-install-recommends \
      libabsl-dev
# - sf
RUN apt-get -y update && apt-get install -y \
  libudunits2-dev libgdal-dev libgeos-dev libproj-dev
# RUN R -e "install.packages('sf')"
# - gsl
RUN apt-get -y update && apt-get install -y \
  libgsl-dev
# RUN R -e "install.packages('gsl')"
# - fmesher
RUN apt-get update && apt-get install -y --no-install-recommends \
      libudunits2-dev
# RUN R -e "install.packages('fmesher')"
# - INLA
RUN R -e "install.packages('INLA',repos=c(getOption('repos'),INLA='https://inla.r-inla-download.org/R/stable'), dep=TRUE)"
# - Magick++
RUN apt-get update && apt-get install -y --no-install-recommends \
      libmagick++-dev
# - libxml-2.0
RUN apt-get update && apt-get install -y --no-install-recommends \
      libxml2-dev

###
# install all package dependencies
###
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
RUN R -e "package<-desc::desc()\$get_field('Package');pckgs<-unique(renv::dependencies('$PACKAGE_PATH')[,'Package']);pres_pckgs<-installed.packages()[,'Package'];install.packages(pckgs[!(pckgs %in% pres_pckgs) & !(pckgs == package)])"
