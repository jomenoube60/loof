#!/bin/sh
cd loof
find . -name "*.orig" -exec rm {} \;
find . -name "*.sw?" -exec rm {} \;
zip -9r ../loof.love .

cd ..
cat /bin/love loof.love > loof_lnx
chmod +x loof_lnx

mkdir loof_win32
cp -r love*win*/*.dll loof_win32/
cat love*win*/love.exe loof.love > loof_win32/loof.exe

zip -9r loof-win32.zip loof_win32
rm -fr loof_win32
