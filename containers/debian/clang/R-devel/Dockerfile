FROM rhub/debian-clang-devel

# defines the flavour (e.g. FLAVOUR=)
ARG FLAVOUR
# # sets the date for the CRAN snapshot (e.g. BUILD_DATE=2023-12-20)
# ARG BUILD_DATE

# Unsure why this is needed as openssl seems to be installed already
RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl-dev \
  libcurl4-openssl-dev

# add R to PATH
ENV PATH="/opt/$FLAVOUR/bin:${PATH}"

# ENV PATH "$PATH:/opt/R-devel/bin/"
# Set a mirror for CRAN
RUN echo 'options(repos =c(CRAN = "https://cran.rstudio.com"))' \
    >> /opt/$FLAVOUR/lib/R/library/base/R/Rprofile

# Get and install packages for local debugging
RUN R -e "install.packages('devtools')" \
 && R -e "install.packages('remotes')"

# Install dependencies not managed by CRAN
# lme4:
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgsl-dev
      libnlopt-dev
RUN R -e "install.packages('lme4')"
# rjags:
RUN apt-get update && apt-get install -y --no-install-recommends \
      jags
RUN R -e "install.packages('rjags')"
