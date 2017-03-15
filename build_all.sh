#!/bin/bash

packages=(
  "stdeb"
  "pip"
  "setuptools"
  "six"
  "pbr"
  "enum-compat"
  "eventlet"
  "dib-utils"
  "funcsigs"
  "debtcollector"
  "positional"
  "requests"
  "stevedore"
  "iso8601"
  "keystoneauth1"
  "oslo.serialization"
  "oslo.i18n"
  "netaddr"
  "rfc3986"
  "oslo.config"
  "monotonic"
  "oslo.utils"
  "python-keystoneclient"
  "requestsexceptions"
  "os-client-config"
  "osc-lib"
  "oslo.context"
  "oslo.log"
  "python-heatclient"
  "python-zaqarclient"
  "dogpile.cache"
  "os-apply-config"
  "os-refresh-config"
  "os-collect-config"
)

for ((a=0; a < ${#packages[*]} ; a++))
do
    ./build_source_package.sh ${packages[a]}
    echo --------------------------------------------
done
