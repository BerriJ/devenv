FROM ubuntu:focal

SHELL ["/bin/bash", "-c"]

ENV R_VERSION 4.0.3
ENV R_REPOS https://packagemanager.rstudio.com/cran/__linux__/focal/2021-02-09
ENV DISPLAY :0
ENV TZ Europe/Berlin

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG DEBIAN_FRONTEND=noninteractive

# Add non root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -rm -d /home/$USERNAME -s /bin/bash -g root --uid $USER_UID --gid $USER_GID $USERNAME \
    && addgroup $USERNAME staff \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

COPY package_lists /package_lists
COPY install_scripts /install_scripts

COPY --chown=$USERNAME .misc/.zshrc /home/$USERNAME/.
COPY --chown=$USERNAME .misc/.Rprofile /home/$USERNAME/.

# Ubuntu Setup
RUN apt-get -y --no-install-recommends install \
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
    git clone https://github.com/sindresorhus/pure.git /home/$USERNAME/.zsh/pure

# Install Python
RUN apt-get -y --no-install-recommends install python3-pip && \
    # Python packages
    pip3 install -U --no-cache-dir \
    $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')

# Install R
RUN chmod +x install_scripts/install_r.sh &&\
    install_scripts/install_r.sh \
    && echo "options(repos = c(REPO_NAME = '$R_REPOS'))" >> /home/$USERNAME/.Rprofile \
    # R packages on CRAN / RSPM
    && install2.r -error --ncpus 1 --repos $R_REPOS \
    $(grep -o '^[^#]*' package_lists/r_packages.txt | tr '\n' ' ') \
    # R packages on Github
    &&installGithub.r --repos $R_REPOS \
    $(grep -o '^[^#]*' package_lists/r_packages_github.txt | tr '\n' ' ')

# Install vcpkg C++ dependency manager
RUN git clone https://github.com/Microsoft/vcpkg /usr/vcpkg \
    && cd /usr/vcpkg \
    && ./bootstrap-vcpkg.sh \
    && ./vcpkg integrate install

ENV PATH "/usr/vcpkg:${PATH}"

# Install Latex
RUN chmod +x install_scripts/install_latex.sh &&\
    install_scripts/install_latex.sh \
    && export PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}" \
    && tlmgr install \
    $(grep -o '^[^#]*' package_lists/latex_packages.txt | tr '\n' ' ')

# Set Latex Path
ENV PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"

# Switch to non-root user
USER $USERNAME

RUN chown --recursive $USERNAME:$USERNAME /usr/local/texlive

# Set the default shell to zsh rather than bash
ENTRYPOINT [ "/bin/zsh" ]