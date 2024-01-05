FROM rhub/fedora-clang-devel

# defines the flavour (e.g. FLAVOUR=)
ARG FLAVOUR
ARG REPO_PATH
ARG SSH_PRIV_KEY 
# # sets the date for the CRAN snapshot (e.g. BUILD_DATE=2023-12-20)
# ARG BUILD_DATE

# Update package repositories
RUN dnf check-update && dnf -y install \
  openssl-devel \
  libcurl-devel

# add R to PATH
ENV PATH="/opt/$FLAVOUR/bin:${PATH}"

# ENV PATH "$PATH:/opt/R-devel/bin/"
# Set a mirror for CRAN
# diff to debian: /lib/ > /lib64/
RUN echo 'options(repos =c(CRAN = "https://cran.rstudio.com"))' \
    >> /opt/$FLAVOUR/lib64/R/library/base/R/Rprofile

# Get and install packages for local debugging
RUN R -e "install.packages('devtools')" \
 && R -e "install.packages('remotes')" \
 && R -e "install.packages('R.rsp')" \ 
 && R -e "install.packages('renv')"

# Install dependencies not managed by CRAN
# lme4:
RUN dnf -y \
      libgsl-dev \
      libnlopt-dev
# RUN R -e "install.packages('lme4')"
# rjags:
RUN dnf -y \
      jags \
      git \
      openssh-client

# RUN R -e "install.packages('rjags')"
# Graphviz
RUN R -e "install.packages('BiocManager')" \
 && R -e "BiocManager::install('Rgraphviz')"
# INLA
# - sf
RUN dnf -y \
  libudunits2-dev libgdal-dev libgeos-dev libproj-dev
# RUN R -e "install.packages('sf')"
# - gsl
RUN dnf -y \
  libgsl-dev
# RUN R -e "install.packages('gsl')"
# - fmesher
RUN dnf -y \
      libudunits2-dev
# RUN R -e "install.packages('fmesher')"
# - INLA
RUN R -e "install.packages('INLA',repos=c(getOption('repos'),INLA='https://inla.r-inla-download.org/R/stable'), dep=TRUE)"

###
# install all abn dependencies
###
WORKDIR /root/
# get a shallow copy of the target repository
RUN --mount=type=secret,id=key,dst=/root/.ssh/key GIT_SSH_COMMAND="ssh -i /root/.ssh/key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone --depth=1 git@$REPO_PATH target
WORKDIR target/
# get a list of all dependencies; install remaining packages
# NOTE: abn is hardcoded here
RUN R -e 'pckgs<-unique(renv::dependencies("abn")$Package);pres_pckgs<-installed.packages()[,"Package"];install.packages(pckgs[!(pckgs %in% pres_pckgs)])'
