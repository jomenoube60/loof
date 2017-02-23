#!/bin/sh

rm -fr *.zip

cd loof
find . -name "*.orig" -exec rm {} \;
find . -name "*.sw?" -exec rm {} \;
zip -9r ../loof.love .

cd ..
cat /bin/love loof.love > loof_lnx
chmod +x loof_lnx

pkg='windows64'

D="loof-$pkg"
mkdir $D
cp -r love*win*/*.dll $D
cat love*win*/love.exe loof.love > $D/loof.exe
zip -9r $D.zip $D
rm -fr $D

pkg='linux64'

D="loof-$pkg"
mkdir $D
cp -a /lib/liblove.so* $D
cat /bin/love loof.love > $D/loof
chmod +x $D/loof
zip -9r $D.zip $D
rm -fr $D

scp *.zip planet:www/vrac/love/
