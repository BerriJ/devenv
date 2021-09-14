#!/bin/bash

# Set up and install R
apt-get update
# apt-get install -y --no-install-recommends \
# python3 \
# pandoc \
# gdb \
# vim-tiny \
# apt-transport-https \
# software-properties-common \
# dirmngr \
# gnupg-agent \
# fontconfig \
# libcurl4-openssl-dev \
# openssl \
# libssl-dev \
# libmagick++-dev \
# netbase \
# libxml2-dev \
# libgsl-dev \
# libudunits2-dev \
# libgdal-dev \
# libharfbuzz-dev \
# libfribidi-dev

apt-get -y install --no-install-recommends \
      ca-certificates \
      less \
      libopenblas-base \
      vim-tiny \
      wget \
      dirmngr \
      gpg \
      gpg-agent

BUILDDEPS="libpoppler-cpp-dev"

# Install r build dependencies
apt-get install -y --no-install-recommends $BUILDDEPS

# Install R
echo "deb http://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" >> /etc/apt/sources.list
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add -
apt-get update
apt-get -y install --no-install-recommends r-base=${R_VERSION}* r-base-core=${R_VERSION}* \
r-recommended=${R_VERSION}* r-base-dev=${R_VERSION}* r-cran-littler

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
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*

