#!/bin/sh

cd ~

# clean
echo 'Start to clean vim folders.'
rm ~/.vimrc
rm -rf ~/.vim
rm -rf ~/.vim.d
echo 'Cleaned.'

# .vimrc & vundle
echo 'Start to download vim configure files.'
wget --quiet https://raw.githubusercontent.com/wildskyf/vim.d/master/.vimrc

# junegunn/vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# .vimrc & .vim.d
git clone git@github.com:wildskyf/vim.d.git .vim.d
ln .vim.d/.vimrc ./.vimrc
cd ~/.vim.d
echo 'Downloaded.'

echo 'Start to install vim packages.'
vim -c 'PlugInstall' -c 'qa!'
echo 'Installed.'

echo ''
echo '========================================================================'
echo 'Finished. You might need to install or compile some dependency packages.'
echo '========================================================================'
