FROM ubuntu:focal

SHELL ["/bin/bash", "-c"]

ENV R_VERSION=4.1.1 \
    # See https://packagemanager.rstudio.com/client/#/repos/1/overview
    R_REPOS=https://packagemanager.rstudio.com/all/__linux__/focal/4561333 \
    DISPLAY=:0 \
    TZ=Europe/Berlin

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG DEBIAN_FRONTEND=noninteractive

# Add non root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -rm -d /home/$USERNAME -s /bin/bash -g root --uid $USER_UID --gid $USER_GID $USERNAME \
    && addgroup $USERNAME staff

COPY package_lists /package_lists
COPY install_scripts /install_scripts

COPY --chown=$USERNAME .misc/.zshrc /home/$USERNAME/.
COPY --chown=$USERNAME .misc/.Rprofile /home/$USERNAME/.

# Ubuntu Setup
RUN apt-get update &&\
    apt-get -y --no-install-recommends install \
    apt-transport-https \
    software-properties-common \
    git \
    build-essential \
    tar \
    curl \
    zip \
    unzip \
    xclip \
    zsh \
    gnupg2 \
    nano \
    ssh-client \
    locales &&\
    locale-gen en_US.UTF-8 &&\
    update-locale LANG=en_US.UTF-8 &&\
    git clone --depth=1 https://github.com/sindresorhus/pure.git /home/$USERNAME/.zsh/pure \
    && rm -rf /home/$USERNAME/.zsh/pure/.git

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Install Python
RUN apt-get -y --no-install-recommends install python3-pip && \
    # Python packages
    pip3 install -U --no-cache-dir \
    $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')

# Install R
RUN chmod +x install_scripts/install_r.sh &&\
    install_scripts/install_r.sh \
    # R packages on RSPM
    && install2.r --error --skipinstalled --ncpus 32 \
    $(grep -o '^[^#]*' package_lists/r_packages.txt | tr '\n' ' ') \
    # R packages on Github
    &&installGithub.r \
    $(grep -o '^[^#]*' package_lists/r_packages_github.txt | tr '\n' ' ') \
    && chown --recursive $USERNAME:$USERNAME /usr/local/lib/R/site-library

# Install vcpkg C++ dependency manager
RUN git clone --depth=1 https://github.com/Microsoft/vcpkg /usr/local/vcpkg \
    && rm -rf /usr/local/vcpkg/.git \
    && cd /usr/local/vcpkg \
    && ./bootstrap-vcpkg.sh \
    && ./vcpkg integrate install \
    && chown --recursive $USERNAME:$USERNAME /usr/local/vcpkg

# Install Latex
RUN chmod +x install_scripts/install_latex.sh &&\
    install_scripts/install_latex.sh \
    && export PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}" \
    && tlmgr install \
    $(grep -o '^[^#]*' package_lists/latex_packages.txt | tr '\n' ' ') \
    && chown --recursive $USERNAME:$USERNAME /usr/local/texlive


# Create folders to mount extensions
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    /home/$USERNAME/.vscode-server-insiders/extensions \
    && chown -R $USERNAME \
    /home/$USERNAME/.vscode-server \
    /home/$USERNAME/.vscode-server-insiders

# Set PATH for user installed python packages, latex and vcpkg
ENV PATH="/home/vscode/.local/bin:${PATH}" \
    PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}" \
    PATH="/usr/local/vcpkg:${PATH}"

# Switch to non-root user
USER $USERNAME

# Set the default shell to zsh rather than bash
ENTRYPOINT [ "/bin/zsh" ]