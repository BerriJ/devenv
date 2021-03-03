#!/bin/bash

# Install r build dependencies
apt-get install -y --no-install-recommends \
curl \
dirmngr \
gnupg-agent \
fontconfig \
pandoc \
perl \
python3-pip \
wget \
libcurl4-openssl-dev \
openssl \
libssl-dev \
libmagick++-dev \
libpoppler-cpp-dev \
netbase \
libxml2-dev \
gdb \
libgsl-dev

# Install R
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
E298A3A825C0D65DFD57CBB651716619E084DAB9
add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
apt-get -y install --no-install-recommends r-base=${R_VERSION}* r-base-core=${R_VERSION}* \
r-recommended=${R_VERSION}* r-base-dev=${R_VERSION}*

# Use littler installation scripts
Rscript -e "install.packages(c('littler', 'docopt'), repos= '$R_REPOS')"
ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r
ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r
ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r

# Install alternative r console
pip3 install -U --no-cache-dir radian