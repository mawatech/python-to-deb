#!/bin/bash
set -e -u

DEBIAN_FRONTEND=noninteractive sudo apt-get update

PACKAGES=""
PACKAGES+=" apt-file"
PACKAGES+=" build-essential"
PACKAGES+=" debhelper"
PACKAGES+=" dh-python"
PACKAGES+=" python-all-dev"
PACKAGES+=" python-requests"
PACKAGES+=" python-setuptools"
PACKAGES+=" python-stdeb"
PACKAGES+=" python-pip"
PACKAGES+=" libyaml-dev"
PACKAGES+=" libxslt1-dev"
PACKAGES+=" libxml2-dev"
PACKAGES+=" git"
PACKAGES+=" libcurl4-gnutls-dev"
PACKAGES+=" libgnutls28-dev"
PACKAGES+=" libssl-dev"
PACKAGES+=" python2.7-celementtree"
PACKAGES+=" python-rpm"

DEBIAN_FRONTEND=noninteractive sudo apt-get install -yq $PACKAGES

sudo pip install -U pip setuptools wheel
