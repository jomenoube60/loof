#!/bin/sh

rm -fr *.zip loof.love

cd loof
find . -name "*.orig" -exec rm {} \;
find . -name "*.sw?" -exec rm {} \;
zip -9ry ../loof.love .

cd ..
cat /bin/love loof.love > loof_lnx
chmod +x loof_lnx

pkg='windows64'

D="loof-$pkg"
mkdir $D
cp -r love*win64*/*.dll $D
cat love*win64*/love.exe loof.love > $D/loof.exe
zip -9ry $D.zip $D
rm -fr $D

pkg='windows32'

D="loof-$pkg"
mkdir $D
cp -r love*win32*/*.dll $D
cat love*win32*/love.exe loof.love > $D/loof.exe
zip -9ry $D.zip $D
rm -fr $D

pkg='linux64'

D="loof-$pkg"
mkdir $D
cp -a /lib/liblove.so* $D
cat /bin/love loof.love > $D/loof
chmod +x $D/loof
zip -9ry $D.zip $D
rm -fr $D

pkg='osx'

D="loof-$pkg"
find Loof.app -iname "*.sw?" -exec rm {} \;
cp Info.plist Loof.app/Contents/Info.plist
cp loof.love Loof.app/Contents/Resources/Loof.love
zip -9ry $D.zip Loof.app

scp *.zip planet:www/loof/pkg/
