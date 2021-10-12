#!/bin/bash

# Install build dependencies
apt-get update
apt-get install -y --no-install-recommends \
wget \
pandoc

# Install Latex
wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
mkdir /install-tl-unx
tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1
echo "selected_scheme scheme-basic" >> /install-tl-unx/texlive.profile
echo "TEXDIR /usr/local/texlive" >> /install-tl-unx/texlive.profile
echo "option_doc 0" >> /install-tl-unx/texlive.profile
echo "option_src 0" >> /install-tl-unx/texlive.profile
/install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile
rm -r /install-tl-unx
rm install-tl-unx.tar.gz

# Additional Perl Modules for Indentation
cpan install Log::Log4perl <<<yes \
install YAML::Tiny \
install YAML::Tiny \
install Log::Dispatch::File \
install File::HomeDir \
install Class::Data::Inheritable \
install Devel::StackTrace

rm -r /tmp/*
rm -r /root/.cpan/build/*
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/apt/lists/*