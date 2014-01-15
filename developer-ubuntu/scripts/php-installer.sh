#!/bin/sh

A2ENMOD="/usr/sbin/a2enmod"
ADDGROUP="/usr/sbin/addgroup"
APTGET="/usr/bin/apt-get"
CAT="/bin/cat"
MKDIR="/bin/mkdir"
MV="/bin/mv"
SUDO="/usr/bin/sudo"

# php5 相關
${SUDO} ${APTGET} install -y apache2 mysql-server php5 php5-mysql php5-mcrypt php5-cli
${SUDO} ${MKDIR} -p /etc/php5/apache2
${CAT} > php.ini <<EOF
display_errors = Off
error_log = /home/logs/php-err.log
expose_php = Off
file_uploads = On
include_path = "."
log_errors = On
magic_quotes_gpc = Off
max_execution_time = 3000
max_input_time = 1200
memory_limit = 300M
post_max_size = 300M
realpath_cache_size = 1M
upload_max_filesize = 310M

[Date]
date.timezone = Asia/Taipei

[Session]
session.name = Ubuntu
session.cookie_lifetime = 86400
session.gc_divisor = 1000
session.bug_compat_42 = 0
session.hash_bits_per_character = 5

[APC]
apc.enable_cli = 1
apc.shm_size = 128
apc.stat_ctime = 1
EOF

${SUDO} ${MV} php.ini /etc/php5/apache2/php.ini

# Enable php5, rewrite, dir module
${SUDO} ${A2ENMOD} rewrite php5 dir
