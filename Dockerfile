FROM ubuntu:jammy@sha256:6120be6a2b7ce665d0cbddc3ce6eae60fe94637c6a66985312d1f02f63cc0bcd

SHELL ["/bin/bash", "-c"]

ENV DISPLAY=:0 \
    TZ=Europe/Berlin

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG DEBIAN_FRONTEND=noninteractive

# Add non root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -rm -d /home/$USERNAME -s /bin/bash -g root --uid $USER_UID --gid $USER_GID $USERNAME \
    && addgroup $USERNAME staff

# Create folders to mount extensions
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    /home/$USERNAME/.vscode-server-insiders/extensions \
    workspaces \
    && chown -R $USERNAME \
    /home/$USERNAME/.vscode-server \
    /home/$USERNAME/.vscode-server-insiders \
    workspaces

# Ubuntu Setup
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections &&\
    apt-get update &&\
    apt-get -y --no-install-recommends install \
    ca-certificates \
    git \
    build-essential \
    ccache \
    netbase \
    zip \
    unzip \
    xclip \
    zsh \
    gnupg2 \
    nano \
    ssh-client \
    fontconfig \
    ttf-mscorefonts-installer \
    locales &&\
    locale-gen en_US.UTF-8 &&\
    locale-gen de_DE.UTF-8 &&\
    update-locale LANG=en_US.UTF-8 &&\
    git clone --depth=1 https://github.com/sindresorhus/pure.git /home/$USERNAME/.zsh/pure \
    && rm -rf /home/$USERNAME/.zsh/pure/.git \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Font config
# "LM Roman 10", "Times New Roman" ... use `showtext` package in R
COPY .misc/lmroman10-regular-webfont.ttf /usr/share/fonts/truetype/.
COPY .misc/lmroman10-italic-webfont.ttf /usr/share/fonts/truetype/.
COPY .misc/lmroman10-bolditalic-webfont.ttf /usr/share/fonts/truetype/.
COPY .misc/lmroman10-bold-webfont.ttf /usr/share/fonts/truetype/.

RUN fc-cache -f -v

# Install phantomjs
COPY install_scripts/install_phantomjs.sh /install_scripts/install_phantomjs.sh

RUN chmod +x install_scripts/install_phantomjs.sh &&\
    install_scripts/install_phantomjs.sh

# Install vcpkg C++ dependency manager
# RUN git clone --depth=1 https://github.com/Microsoft/vcpkg /usr/local/vcpkg \
#     && rm -rf /usr/local/vcpkg/.git \
#     && cd /usr/local/vcpkg \
#     && ./bootstrap-vcpkg.sh \
#     && ./vcpkg integrate install \
#     && chown --recursive $USERNAME:$USERNAME /usr/local/vcpkg
# 
# ENV PATH="/usr/local/vcpkg:${PATH}"

# Install Python
COPY package_lists/python_packages.txt /package_lists/python_packages.txt

RUN apt-get update &&\
    apt-get -y --no-install-recommends install python3-pip && \
    # Python packages
    pip3 install -U --no-cache-dir \
    $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')  \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

# Set PATH for user installed python packages
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Install Latex
COPY install_scripts/install_latex.sh /install_scripts/install_latex.sh
COPY package_lists/latex_packages.txt /package_lists/latex_packages.txt

RUN chmod +x install_scripts/install_latex.sh &&\
    install_scripts/install_latex.sh \
    && export PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}" \
    && tlmgr option -- autobackup 0 \
    && tlmgr option -- docfiles 0 \
    && tlmgr option -- srcfiles 0 \
    && tlmgr install \
    $(grep -o '^[^#]*' package_lists/latex_packages.txt | tr '\n' ' ') \
    && chown --recursive $USERNAME:$USERNAME /usr/local/texlive

# Set Latex Path
ENV PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"

# Install R
ENV R_VERSION=4.3.0

# Set RSPM snapshot see:
# https://packagemanager.rstudio.com/client/#/repos/1/overview
ENV R_REPOS=https://packagemanager.posit.co/cran/__linux__/jammy/2023-06-14

COPY install_scripts/install_r.sh /install_scripts/install_r.sh
COPY package_lists/r_packages.txt /package_lists/r_packages.txt
COPY package_lists/r_packages_github.txt /package_lists/r_packages_github.txt

RUN chmod +x install_scripts/install_r.sh &&\
    install_scripts/install_r.sh

COPY --chown=$USERNAME .misc/.zshrc /home/$USERNAME/.

COPY --chown=$USERNAME .misc/.Rprofile /home/$USERNAME/.

RUN mkdir /home/$USERNAME/.R && chown -R $USERNAME /home/$USERNAME/.R
COPY --chown=$USERNAME .misc/Makevars /home/$USERNAME/.R/.

RUN mkdir /home/$USERNAME/.ccache && chown -R $USERNAME /home/$USERNAME/.ccache
COPY --chown=$USERNAME .misc/ccache.conf /home/$USERNAME/.ccache/.

# Switch to non-root user
USER $USERNAME

# Start zsh
CMD [ "zsh" ]