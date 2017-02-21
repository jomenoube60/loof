#!/bin/sh
cd loof
find . -name "*.orig" -exec rm {} \;
find . -name "*.sw?" -exec rm {} \;
zip -9r ../loof.love .
