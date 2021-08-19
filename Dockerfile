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
    update-locale LANG="en_US.UTF-8" &&\
    git clone --depth=1 https://github.com/sindresorhus/pure.git /home/$USERNAME/.zsh/pure \
    && rm -rf /home/$USERNAME/.zsh/pure/.git

# Install Python
RUN apt-get -y --no-install-recommends install python3-pip && \
    # Python packages
    pip3 install -U --no-cache-dir \
    $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')

# Set PATH for user installed python packages
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Install R
RUN chmod +x install_scripts/install_r.sh &&\
    install_scripts/install_r.sh \
    && echo "options(repos = c(REPO_NAME = '$R_REPOS'))" >> /home/$USERNAME/.Rprofile \
    # R packages on CRAN / RSPM
    && install2.r -error --ncpus 32 --repos $R_REPOS \
    $(grep -o '^[^#]*' package_lists/r_packages.txt | tr '\n' ' ') \
    # R packages on Github
    &&installGithub.r --repos $R_REPOS \
    $(grep -o '^[^#]*' package_lists/r_packages_github.txt | tr '\n' ' ') \
    && chown --recursive $USERNAME:$USERNAME /usr/local/lib/R/site-library

RUN echo "LANG=en_US.UTF-8" >> ~/.Renviron
RUN Rscript -e "Sys.getlocale()"
RUN Rscript -e "remotes::install_github('ManuelHentschel/vscDebugger@v0.4.7', repos= '$R_REPOS')"

# Install vcpkg C++ dependency manager
RUN git clone --depth=1 https://github.com/Microsoft/vcpkg /usr/local/vcpkg \
    && rm -rf /usr/local/vcpkg/.git \
    && cd /usr/local/vcpkg \
    && ./bootstrap-vcpkg.sh \
    && ./vcpkg integrate install \
    && chown --recursive $USERNAME:$USERNAME /usr/local/vcpkg

ENV PATH "/usr/local/vcpkg:${PATH}"

# Install Latex
RUN chmod +x install_scripts/install_latex.sh &&\
    install_scripts/install_latex.sh \
    && export PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}" \
    && tlmgr install \
    $(grep -o '^[^#]*' package_lists/latex_packages.txt | tr '\n' ' ') \
    && chown --recursive $USERNAME:$USERNAME /usr/local/texlive

# Set Latex Path
ENV PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"

# Create folders to mount extensions
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    /home/$USERNAME/.vscode-server-insiders/extensions \
    && chown -R $USERNAME \
    /home/$USERNAME/.vscode-server \
    /home/$USERNAME/.vscode-server-insiders

# Switch to non-root user
USER $USERNAME

# Set the default shell to zsh rather than bash
ENTRYPOINT [ "/bin/zsh" ]