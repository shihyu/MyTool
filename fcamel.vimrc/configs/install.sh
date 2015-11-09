#!/bin/bash

for f in .bash_completions .bashrc_public .hgrc .screenrc .vim .vimrc .gdbinit
do
    cp -irp $f ~
done

echo -e "\nsource ~/.bashrc_public" >> ~/.bashrc
echo -e "\nsource ~/.bashrc_private" >> ~/.bashrc

touch ~/.bashrc_private
chmod 600 ~/.bashrc_private

mkdir -p ~/bin/
cp -r bin/* ~/bin/
mkdir -p ~/dev/
cp -r gdb ~/dev/

# vim
touch ~/.vimrc_private
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
