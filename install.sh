#!/bin/bash
ln -s ~/.vim/.vimrc ~/.vimrc
chmod +x ~/.vim/update_submodules.sh
cd ~/.vim

git submodule init
git submodule update
