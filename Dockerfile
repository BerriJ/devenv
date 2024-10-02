FROM ubuntu:jammy@sha256:58b87898e82351c6cf9cf5b9f3c20257bb9e2dcf33af051e12ce532d7f94e3fe

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
  cmake \
  ninja-build \
  ccache \
  gfortran \
  netbase \
  zip \
  unzip \
  xclip \
  zsh \
  lftp \
  gnupg2 \
  nano \
  gdb \
  ssh-client \
  fontconfig \
  pkg-config \
  default-libmysqlclient-dev \
  ttf-mscorefonts-installer \
  locales &&\
  locale-gen en_US.UTF-8 &&\
  locale-gen de_DE.UTF-8 &&\
  update-locale LANG=en_US.UTF-8 &&\
  git clone --depth=1 https://github.com/sindresorhus/pure.git /home/$USERNAME/.zsh/pure \
  && rm -rf /home/$USERNAME/.zsh/pure/.git \
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

# Install quarto
ENV QUARTO_VERSION="1.4.551"
COPY install_scripts/install_quarto.sh /install_scripts/install_quarto.sh
RUN chmod +x install_scripts/install_quarto.sh &&\
  install_scripts/install_quarto.sh

RUN wget https://github.com/jgm/pandoc/releases/download/3.1.6.2/pandoc-3.1.6.2-1-amd64.deb &&\
  dpkg -i pandoc-3.1.6.2-1-amd64.deb

# Install phantomjs
COPY install_scripts/install_phantomjs.sh /install_scripts/install_phantomjs.sh

RUN chmod +x install_scripts/install_phantomjs.sh &&\
  install_scripts/install_phantomjs.sh

# Install vcpkg C++ dependency manager
RUN git clone --depth=1 https://github.com/Microsoft/vcpkg --branch 2024.04.26 /usr/local/vcpkg \
  && rm -rf /usr/local/vcpkg/.git \
  && cd /usr/local/vcpkg \
  && ./bootstrap-vcpkg.sh \
  && ./vcpkg integrate install \
  && /usr/local/vcpkg/vcpkg install armadillo \
  && /usr/local/vcpkg/vcpkg install pybind11 \
  && chown --recursive $USERNAME:$USERNAME /usr/local/vcpkg

ENV PATH="/usr/local/vcpkg:${PATH}"

# Install Python CARMA
RUN git clone --depth=1 https://github.com/RUrlus/carma.git /usr/local/carma \
  && rm -rf /usr/local/carma/.git \
  && cd /usr/local/carma \
  && mkdir build \
  && cd build \
  && cmake -DCARMA_INSTALL_LIB=ON .. \
  && cmake --build . --config Release --target install \
  && rm -rf /usr/local/carma

# Install Python
COPY package_lists/python_packages.txt /package_lists/python_packages.txt

RUN apt-get update &&\
  apt-get -y --no-install-recommends install \
  python3-pip  \
  python3-dev \
  python3-venv && \
  # Python packages
  pip3 install -U --no-cache-dir \
  $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')  \
  && apt-get autoclean -y \
  && rm -rf /var/lib/apt/lists/*

# Set PATH for user installed python packages
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Install Latex
COPY install_scripts/install_latex.sh /tmp/install_latex.sh
COPY package_lists/latex_packages.txt /tmp/latex_packages.txt

RUN chmod +x /tmp/install_latex.sh &&\
  /tmp/install_latex.sh \
  && export PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}" \
  && tlmgr option -- autobackup 0 \
  && tlmgr option -- docfiles 0 \
  && tlmgr option -- srcfiles 0 \
  && tlmgr install \
  $(grep -o '^[^#]*' /tmp/latex_packages.txt | tr '\n' ' ') \
  && chown --recursive $USERNAME:$USERNAME /usr/local/texlive

# Set Latex Path
ENV PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"

# Install R
ENV R_VERSION=4.4.1

# Set RSPM snapshot see:
# https://packagemanager.posit.co/client/#/repos/cran/setup?r_environment=other&snapshot=2023-10-04&distribution=ubuntu-22.04
ENV R_REPOS=https://packagemanager.posit.co/cran/__linux__/jammy/2024-10-01

COPY install_scripts/install_r.sh /tmp/install_r.sh
COPY package_lists/r_packages.txt /tmp/r_packages.txt
COPY package_lists/r_packages_github.txt /tmp/r_packages_github.txt

RUN chmod +x /tmp/install_r.sh &&\
  /tmp/install_r.sh

COPY --chown=$USERNAME .misc/.zshrc /home/$USERNAME/.

COPY --chown=$USERNAME .misc/.Rprofile /home/$USERNAME/.

RUN mkdir /home/$USERNAME/.R && chown -R $USERNAME /home/$USERNAME/.R
COPY --chown=$USERNAME .misc/Makevars /home/$USERNAME/.R/.

RUN mkdir /home/$USERNAME/.ccache && chown -R $USERNAME /home/$USERNAME/.ccache
COPY --chown=$USERNAME .misc/ccache.conf /home/$USERNAME/.ccache/.

RUN chown -R $USERNAME /usr/local/lib
RUN chown -R $USERNAME /usr/local/include

# Switch to non-root user
USER $USERNAME

# Start zsh
CMD [ "zsh" ]