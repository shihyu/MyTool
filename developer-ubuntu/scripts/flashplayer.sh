#!/bin/sh

APTGET="/usr/bin/apt-get"
SUDO="/usr/bin/sudo"

${SUDO} /usr/bin/add-apt-repository ppa:sevenmachines/flash
${SUDO} ${APTGET} update
${SUDO} ${APTGET} install flashplugin64-installer
