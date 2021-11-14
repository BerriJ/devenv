#!/bin/bash

echo "deb http://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" >> /etc/apt/sources.list
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add -
apt-get update

apt-get update

BUILDDEPS="libssl-dev"

RUNDEPS="ca-certificates \
      less \
      libatlas-base-dev \
      libxml2-dev \
      vim-tiny \
      wget \
      dirmngr \
      pandoc \
      libmagick++-dev \
      libpoppler-cpp-dev \
      libudunits2-dev \
      libproj-dev \
      libgdal-dev \
      libgeos-dev \
      libharfbuzz-dev \
      libfribidi-dev"

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

# Install alternative r console
pip3 install -U --no-cache-dir radian

# R packages on RSPM
install2.r --error --skipinstalled --ncpus 32 \
    $(grep -o '^[^#]*' package_lists/r_packages.txt | tr '\n' ' ')

# R packages on Github
installGithub.r \
    $(grep -o '^[^#]*' package_lists/r_packages_github.txt | tr '\n' ' ')

chown --recursive $USERNAME:$USERNAME /usr/local/lib/R/site-library

rm -r /tmp/*
apt-get remove --purge -y $BUILDDEPS
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*

