#!/usr/bin/env bash
# This script install PhantomJS in your Debian/Ubuntu System
#
# This script must be run as root:
# sudo sh install_phantomjs.sh
#

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

apt-get update
apt-get -y --no-install-recommends install wget curl

PHANTOM_JS_LATEST=$(curl -s https://bitbucket.org/ariya/phantomjs/downloads/ | grep -i -e zip -e bz2 | grep -vi beta | grep -i linux-x86_64 | grep -v symbols | cut -d '>' -f 2 | cut -d '<' -f 1 | head -n 1)
PHANTOM_VERSION=${PHANTOM_JS_LATEST%-*-*.*.*}
ARCH=$(uname -m)

if ! [ $ARCH = "x86_64" ]; then
	$ARCH="i686"
fi

PHANTOM_JS="$PHANTOM_VERSION-linux-$ARCH"

apt-get update
apt-get -y install build-essential chrpath libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev

cd ~
wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2
tar xvjf $PHANTOM_JS.tar.bz2

mv $PHANTOM_JS /usr/local/share
ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin