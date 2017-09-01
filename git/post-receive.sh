#!/bin/bash

# Unset any git variables for a clean pull
# unset $(git rev-parse --local-env-vars)

# Git pull
cd /home/UNAME/app
sudo -u UNAME git pull

# Perform deploy
# ./deploy.sh

echo Finished deploy
