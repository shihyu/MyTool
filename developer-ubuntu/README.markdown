rails-developer-ubuntu
======================

Build a developer environment of rails in ubuntu

Environment
-----------

    Ubuntu Version: Ubuntu Desktop Edition 10.04 LTS 64bit
    Editor: vim
    Ruby version: REE(Ruby Enterprise Edition)
    Web server: apache (Option.)

Scripts
-------

    ./scripts/ror-installer.sh # It can easily build your enviorment


Update and upgrade the system
-------------------------------

    sudo apt-get update
    sudo apt-get upgrade

Vim, Git, Mysql & other tools
-----------------------------

    sudo apt-get install -y vim git-core tig apache2 mysql-server libmysqlclient16-dev libreadline5-dev

Ruby Enterprise Edition
-----------------------

    wget 'http://rubyforge.org/frs/download.php/71098/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb'
    sudo dpkg -i ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb

Add Ruby Enterprise bin to PATH

    echo 'export PATH="/usr/local/lib/ruby/gems/1.8/bin:$PATH"' >> ~/.profile && . ~/.profile

