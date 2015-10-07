#!/bin/bash
ln -s ~/.vim/.vimrc ~/.vimrc
ln -s ~/.vim/.vimrc ~/.ideavimrc
chmod +x ~/.vim/update_submodules.sh
cd ~/.vim

git submodule init
git submodule update
