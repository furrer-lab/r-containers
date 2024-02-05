ARG TARGET_OS
ARG COMPILER
ARG R_VERSION
# ARG PACKAGE
ARG DESCRIPTION_FILE
ARG REPO_PATH
ARG SSH_PRIV_KEY
ARG JAGS
# # sets the date for the CRAN snapshot (e.g. BUILD_DATE=2023-12-20)
# ARG BUILD_DATE

FROM rhub/${TARGET_OS}-${COMPILER}-${R_VERSION}

# Update package repositories
RUN dnf check-update && dnf -y install \
  openssl-devel \
  libcurl-devel

# add R to PATH
ENV PATH="/opt/R-$R_VERSION/bin:${PATH}"

# ENV PATH "$PATH:/opt/R-devel/bin/"
# Set a mirror for CRAN
# diff to debian: /lib/ > /lib64/
RUN echo 'options(repos =c(CRAN = "https://cran.rstudio.com"))' \
    >> /opt/R-$R_VERSION/lib64/R/library/base/R/Rprofile

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
RUN LD="llvm-ld" CC="/usr/bin/clang" CXX="/usr/bin/clang++ -std=gnu++17 -stdlib=libc++" ./configure --with-blas="-L/opt/R-devel/lib64/R/lib -lRblas" --with-lapack="-L/opt/R-devel/lib64/R/lib -lRlapack" --libdir=/usr/local/lib64 && make && make install
RUN ls /tmp/$JAGS
# ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
# RUN R -e "install.packages('rjags')"
RUN R -e "install.packages('rjags', configure.args = '--enable-rpath')"

# Get and install packages for local debugging
RUN R -e "install.packages('devtools')" \
 && R -e "install.packages('remotes')" \
 && R -e "install.packages('R.rsp')" \
 && R -e "install.packages('renv')"

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

###
# install all package dependencies
###
RUN dnf -y install \
      git \
      openssh-clients
WORKDIR /root/
# get a shallow copy of the target repository
# Note: If the repository is private you must use a deploy token here (ssh key) 
RUN --mount=type=secret,id=key,dst=/root/.ssh/key GIT_SSH_COMMAND="ssh -i /root/.ssh/key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone --depth=1 git@$REPO_PATH target
WORKDIR target/
# get a list of all dependencies; install remaining packages
# escape=\
RUN R -e "package<-desc::desc(file='$DESCRIPTION_FILE')\$get_field('Package');pckgs<-unique(renv::dependencies(package)[,'Package']);pres_pckgs<-installed.packages()[,'Package'];install.packages(pckgs[!(pckgs %in% pres_pckgs)])"
