FROM rhub/debian-clang-devel

ARG FLAVOUR

# add R to PATH
ENV PATH="/opt/$FLAVOUR/bin:${PATH}"
# ENV PATH "$PATH:/opt/R-devel/bin/"
# Set a mirror for CRAN
RUN echo 'options(repos =c(CRAN = "https://cran.rstudio.com"))' \
    >> /opt/$FLAVOUR/lib/R/library/base/R/Rprofile

# Get and install system dependencies
RUN R -e "install.packages('remotes')" \
 && R -e "remotes::install_github('r-hub/sysreqs')"

# COPY ./install_jags_fedora_source.sh /opt/src/scripts/install_jags_fedora_source.sh
# COPY ./install_Rpackages_fedora_source.R /opt/src/scripts/install_Rpackages_fedora_source.R
# 
# RUN dnf upgrade --refresh && dnf install -y \
#     cmake \
#     gsl \
#     nlopt \
#     qpdf \
#     devscripts \
#     wget \
#     lapack-devel
# 
# # Build jags from source
# RUN chmod 700 /opt/src/scripts/install_jags_fedora_source.sh
# RUN /opt/src/scripts/install_jags_fedora_source.sh
# 
# # Install R packages
# RUN /opt/R-devel/bin/R CMD BATCH /opt/src/scripts/install_Rpackages_fedora_source.R
# 
