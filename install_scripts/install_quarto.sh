apt-get update
apt-get -y --no-install-recommends install curl gdebi-core

curl -o quarto-linux-amd64.deb -L https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb

gdebi --non-interactive quarto-linux-amd64.deb

rm quarto-linux-amd64.deb