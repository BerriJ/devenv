FROM ubuntu:focal

ENV R_VERSION=4.0.2
ENV R_REPOS=https://packagemanager.rstudio.com/all/__linux__/focal/311

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Germany

RUN apt-get -y update && \
    apt-get -y upgrade &&\
    apt-get -y install software-properties-common &&\
    # -------------------------------Python-----------------------------------#
    apt-get -y install python3-pip &&\
    # Install Python packages
    pip3 install numpy && \
    pip3 install pandas && \
    # ----------------------------------R-------------------------------------#
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 &&\
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' &&\
    apt-get -y install r-base=${R_VERSION}* r-base-core=${R_VERSION}* r-recommended=${R_VERSION}* r-base-dev=${R_VERSION}* &&\
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
    tidyverse \
    remotes &&\
    Rscript -e "options(repos = c(REPO_NAME = '$R_REPOS'))" &&\
    # -------------------------------Latex------------------------------------#
    apt-get -y install texlive texlive-science texlive-latex-extra texlive-lang-german \
    texlive-xetex latexmk