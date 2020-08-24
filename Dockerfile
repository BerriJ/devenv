FROM ubuntu:focal

SHELL ["/bin/bash", "-c"]

ENV R_VERSION 4.0.2
ENV R_REPOS https://packagemanager.rstudio.com/all/__linux__/focal/311
ENV DISPLAY :0
ENV TZ Europe/Germany

ARG DEBIAN_FRONTEND=noninteractive

COPY package_lists /package_lists
COPY install_scripts /install_scripts

# Ubuntu Setup
RUN apt-get -y update &&\
    apt-get -y --no-install-recommends install\
    software-properties-common \
    wget \
    git \
    locales &&\
    locale-gen en_US.UTF-8 &&\
    export LC_ALL=en_US.UTF-8 &&\
    export LANG=en_US.UTF-8 && \
    # Cleanup apt cache
    rm -rf /var/lib/apt/lists/*

# Python setup
RUN apt-get -y update &&\
    apt-get -y --no-install-recommends install python3-pip && \
    # Cleanup apt cache
    rm -rf /var/lib/apt/lists/*

# Python packages
RUN pip3 install -U --no-cache-dir\
    $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')

# R Setup
RUN chmod +x /install_scripts/install_r.sh &&\
    /install_scripts/install_r.sh

# R packages
RUN install2.r -error --ncpus 16 --repos $R_REPOS \
    $(grep -o '^[^#]*' package_lists/r_packages.txt | tr '\n' ' ')

# Install Latex
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz; \
    mkdir /install-tl-unx; \
    tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1; \
    echo "selected_scheme scheme-basic" >> /install-tl-unx/texlive.profile; \
    echo "TEXDIR /usr/local/texlive" >> /install-tl-unx/texlive.profile; \
    /install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile; \
    rm -r /install-tl-unx; \
    rm install-tl-unx.tar.gz &&\
    # Additional Perl Modules for Indentation
    cpan install Log::Log4perl <<<yes \
    install YAML::Tiny \
    install YAML::Tiny \
    install Log::Dispatch::File \
    install File::HomeDir

# Set Latex Path
ENV PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"

# Install latex packages
RUN tlmgr install \
    $(grep -o '^[^#]*' package_lists/latex_packages.txt | tr '\n' ' ')