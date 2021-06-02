# VS Code Devcontainer and Docker Image for Coding in R, Python, and Latex

Obtain the latest stable image with:

    docker pull ghcr.io/berrij/devenv:latest

## Introduction

This Ubuntu-based docker image intends to deliver a fully isolated dev environment for Python, R and Latex. Extend it as needed by adding or removing components.

It is intended that you use this image with a [VS Code Devcontainer](https://code.visualstudio.com/docs/remote/containers). VS Code will automatically install all required extensions for code formatting, linting, execution, and debugging.

## Contents

- R 4.X.X
- Texlive 2021
- Python 3.8.X

# Setup using VS-Code

## System requirements

- Install [Git](https://git-scm.com/downloads)
- Install [VS-Code](https://code.visualstudio.com/)
- Install [Docker Desktop](https://www.docker.com/get-started)

## Getting Started

- [Fork the berrij/devenv github repository](https://github.com/BerriJ/devenv/fork).
- Clone the forked repository.
- Open the repository inside VS Code and install the recommended extensions.
- VS Code should ask you if you want to reopen the workspace in a container. It will automatically download the latest master build, install extensions, and mount your current workspace.

## SSH and GPG Keys

Look [here](https://code.visualstudio.com/docs/remote/containers#_using-ssh-keys) on how to forward your local keys into the container.


# Without VS-Code:

You may need to run:

    xhost local:root 

locally to grant access to the local x11 display server. This is necessary for R graphics devices to work.

## Run using:

    docker run -it --rm --network=host -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix ghcr.io/berrij/devenv:dev

## Explanation:

    -it             
    # Interactive Mode, launches a shell
    
    --rm            
    # Automatically remove the container when it exits
    
    --network=host  
    # Configures the network of the Docker container to use   the host network. This is the simplest way to get access to X11

    -e DISPLAY      
    # Sets the DISPLAY variable to :0. Works ins most cases.
    
    -v /tmp/.X11-unix:/tmp/.X11-unix dev_env:latest
    # Mounts the local .x11 server into the container

# Remove Old Docker Images

You can check the disk usage of Docker by running:

    docker system df

You likely want to add a cronjob to delete old docker images and containers. You can do so the following way:

Edit your crontab with:

    crontab -e

Then add the following line:

    0 18 * * 5 /usr/bin/docker system prune --all --volumes --force

This will remove all unused images not just dangling ones as long as they are older than 10 days.

When using this image with the .devcontainer.json as a devcontainer, a local volume `extensions_cache` / `extensions_cache_insiders` will be created for storing container extensions between container runs. If extensions are updated in the .devcontainer.json this volume has to be deleted:

    docker volume rm extensions_cache
    docker volume rm extensions_cache_insiders

# Issues

If you encounter issues or you want to propose a feature feel free to open an issue on [GitHub](https://github.com/BerriJ/devenv). 
