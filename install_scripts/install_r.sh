#!/bin/bash

# Set up and install R

# Install r build dependencies
apt-get install -y --no-install-recommends \
apt-transport-https \
software-properties-common \
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
libgsl-dev \
libudunits2-dev \
libgdal-dev \
libharfbuzz-dev \
libfribidi-dev \
vim \
cargo

# Install R
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
E298A3A825C0D65DFD57CBB651716619E084DAB9
add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
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