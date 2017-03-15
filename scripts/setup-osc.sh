#!/bin/bash
set -e -u

# install needed packages
pip install -U urlgrabber pycurl M2Crypto

# install osc from git
pip install -U git+https://github.com/openSUSE/osc.git

# create a symlink 'osc'
ln -s /usr/local/bin/osc-wrapper.py /usr/bin/osc
