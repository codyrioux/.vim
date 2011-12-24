#!/bin/bash
ln -s ~/.vim/.vimrc ~/.vimrc
chmod +x ~/.vim/update_submodules.sh

git submodule init
git submodule update
