#!/bin/bash

apt update -qq
# install two helper packages we need
apt install -y --no-install-recommends software-properties-common dirmngr
# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
# Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# add the R 4.X repo from CRAN
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/"

apt-get update

BUILDDEPS="libssl-dev"

RUNDEPS="ca-certificates \
      less \
      jq \
      libatlas-base-dev \
      libxml2-dev \
      vim-tiny \
      wget \
      libmagick++-dev \
      libpoppler-cpp-dev \
      libudunits2-dev \
      libproj-dev \
      libgdal-dev \
      libgsl-dev \
      libgeos-dev \
      libharfbuzz-dev \
      libfribidi-dev \
      curl \
      libgit2-dev \
      qpdf"

# Install R amd dependencies
apt-get install -y --no-install-recommends \
    $BUILDDEPS \
    $RUNDEPS \
    r-base=${R_VERSION}* \
    r-base-core=${R_VERSION}* \
    r-recommended=${R_VERSION}* \
    r-base-dev=${R_VERSION}* \
    r-cran-littler

# Use littler installation scripts
ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r
ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r
ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r

# Replace content from Rprofile.site
rm /usr/lib/R/etc/Rprofile.site

# ## Add default CRAN mirror
echo "options(repos = c(CRAN = '$R_REPOS'), download.file.method = 'libcurl')" >> /usr/lib/R/etc/Rprofile.site

## Set HTTPUserAgent for RSPM (https://github.com/rocker-org/rocker/issues/400)
echo  'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /usr/lib/R/etc/Rprofile.site

# Install docopt which is used by littler to install packages
Rscript -e "install.packages('docopt', repos= '$R_REPOS')"

# R packages on RSPM
install2.r --error --skipinstalled --ncpus 32 \
    $(grep -o '^[^#]*' tmp/r_packages.txt | tr '\n' ' ')

# R packages on Github
installGithub.r \
    $(grep -o '^[^#]*' tmp/r_packages_github.txt | tr '\n' ' ')

# Miniconda for Refinitiv and resp. python dependenies 
# R -e "Refinitiv::install_eikon()"

chown --recursive $USERNAME:$USERNAME /usr/local/lib/R/site-library

apt-get autoclean -y 
apt-get clean 
rm -rf /var/cache/* 
rm -rf /tmp/* 
rm -rf /var/tmp/* 
rm -rf /var/lib/apt/lists/*