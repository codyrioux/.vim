#!/bin/bash
git pull
git submodule init
git submodule update
git submodule foreach git pull origin master
git commit -am "Updated submodules on `date`."
git push
