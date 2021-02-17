FROM ubuntu:focal

SHELL ["/bin/bash", "-c"]

ENV R_VERSION 4.0.3
ENV R_REPOS https://packagemanager.rstudio.com/cran/__linux__/focal/2021-02-09
ENV DISPLAY :0
ENV TZ Europe/Berlin

# Add non root user

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && addgroup $USERNAME staff

ARG DEBIAN_FRONTEND=noninteractive

COPY package_lists /package_lists
COPY install_scripts /install_scripts

# Ubuntu Setup
RUN apt-get -y update &&\
    apt-get -y --no-install-recommends install \
    software-properties-common \
    git \
    xclip \
    zsh \
    gnupg2 \
    nano \
    ssh-client \
    locales &&\
    locale-gen en_US.UTF-8 &&\
    export LC_ALL=en_US.UTF-8 &&\
    export LANG=en_US.UTF-8 &&\
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone &&\
    # Cleanup apt cache
    rm -rf /var/lib/apt/lists/*

# Install Python
RUN apt-get -y update &&\
    apt-get -y --no-install-recommends install python3-pip && \
    # Cleanup apt cache
    rm -rf /var/lib/apt/lists/*

# Python packages
RUN pip3 install -U --no-cache-dir\
    $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')

# Install R
RUN chmod +x /install_scripts/install_r.sh &&\
    /install_scripts/install_r.sh

# R packages on CRAN / RSPM
RUN install2.r -error --ncpus 1 --repos $R_REPOS \
    $(grep -o '^[^#]*' package_lists/r_packages.txt | tr '\n' ' ')

# R packages on Github
RUN installGithub.r --repos $R_REPOS \
    $(grep -o '^[^#]*' package_lists/r_packages_github.txt | tr '\n' ' ')

# Install Latex
RUN chmod +x /install_scripts/install_latex.sh &&\
    /install_scripts/install_latex.sh

# Set Latex Path
ENV PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"

# Install latex packages
RUN tlmgr install \
    $(grep -o '^[^#]*' package_lists/latex_packages.txt | tr '\n' ' ')

RUN chown --recursive $USERNAME:$USERNAME /usr/local/texlive

# Set the default shell to zsh rather than bash
RUN mkdir -p "/home/$USERNAME/.zsh" &&\
    git clone https://github.com/sindresorhus/pure.git "/home/$USERNAME/.zsh/pure"

COPY .misc/.zshrc /home/$USERNAME/.
COPY .misc/.Rprofile /home/$USERNAME/.

RUN echo "options(repos = c(REPO_NAME = '$R_REPOS'))" >> /home/$USERNAME/.Rprofile

USER $USERNAME

RUN echo "options(repos = c(REPO_NAME = '$R_REPOS'))" >> /root/.Rprofile

ENTRYPOINT [ "/bin/zsh" ]