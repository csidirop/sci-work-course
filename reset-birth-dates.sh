#!/bin/sh

if [ $# -gt 0 ]; then
    RESET_COMMIT="$1"
else
    RESET_COMMIT="3d23c3df5c8f630f0c86af7cacd2fc0cf672e291"
fi
set -x
git pull --rebase origin
git checkout "$RESET_COMMIT" data/birth-dates/*
git commit -m "Reset birth dates"
set +x

echo "\nYou can check the latest commit now and then push it to GitHub."
