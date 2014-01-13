#!/bin/sh

APTGET="/usr/bin/apt-get"
DPKG="/usr/bin/dpkg"
SUDO="/usr/bin/sudo"
WGET="/usr/bin/wget"

# init, update packages list
${SUDO} ${APTGET} update
${SUDO} ${APTGET} -y upgrade

# install basic tools
${SUDO} ${APTGET} -y install vim git-core tig apache2 mysql-server

