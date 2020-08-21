FROM ubuntu:focal

ENV R_VERSION 4.0.2
ENV R_REPOS https://packagemanager.rstudio.com/all/__linux__/focal/311
ENV DISPLAY :0
ENV TZ Europe/Germany

ARG DEBIAN_FRONTEND=noninteractive

# Ubuntu Setup
RUN apt-get -y update &&\
    apt-get -y upgrade &&\
    apt-get -y install \
    software-properties-common \
    wget \
    git \
    locales &&\
    locale-gen en_US.UTF-8 &&\
    export LC_ALL=en_US.UTF-8 &&\
    export LANG=en_US.UTF-8

# Python Setup
RUN apt-get -y install python3-pip &&\
    # Install Python packages
    pip3 install -U \
    numpy \
    pandas \
    scipy \
    numdifftools \
    properscoring \
    ipykernel


# R Setup
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
    E298A3A825C0D65DFD57CBB651716619E084DAB9 &&\
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' &&\
    apt-get -y install r-base=${R_VERSION}* r-base-core=${R_VERSION}* \
    r-recommended=${R_VERSION}* r-base-dev=${R_VERSION}* &&\
    # install some dependencies of r packages
    apt-get -y install curl libcurl4-openssl-dev openssl libssl-dev libxml2-dev &&\
    # install alternative r console
    pip3 install -U radian && \
    # Use littler installation scripts
    Rscript -e "install.packages(c('littler', 'docopt'), repos= '$R_REPOS')" &&\
    ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r &&\
    ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r &&\
    ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r &&\
    # install r packages
    install2.r -error --ncpus 16 --repos $R_REPOS \
    languageserver \
    tidyverse \
    forecast \
    reshape2 \
    knitr \
    kableExtra \
    gamlss.dist \
    cowplot \
    data.table &&\
    Rscript -e "options(repos = c(REPO_NAME = '$R_REPOS'))"

# Install Latex
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz; \
    mkdir /install-tl-unx; \
    tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1; \
    echo "selected_scheme scheme-basic" >> /install-tl-unx/texlive.profile; \
    /install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile; \
    rm -r /install-tl-unx; \
    rm install-tl-unx.tar.gz

# Set Latex Path
ENV PATH="/usr/local/texlive/2020/bin/x86_64-linux:${PATH}"

# Install latex packages
RUN tlmgr install \
    collection-fontsextra \
    latexmk \
    beamer \
    standalone \
    xkeyval \
    currfile \
    filehook \
    filemod \
    multirow \
    bbold \
    mathtools \
    eso-pic \
    enumitem \
    relsize \
    pgfplots \
    pdfpages \
    scalerel \
    contour \
    gincltex \
    svn-prov \
    adjustbox \
    collectbox \
    fontspec \
    booktabs \
    pdflscape \
    ec \
    cm-super \
    caption \
    # Optional: Package Documentation
    texdoc \
    # Optional: Linting
    ChkTeX \
    # Optional: Indentation
    latexindent && \
    # Additional Perl Modules for Indentation
    cpan Log::Log4perl <<<yes &&\
    cpan YAML::Tiny module &&\
    cpan Log::Dispatch::File &&\
    cpan File::HomeDir