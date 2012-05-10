#!/bin/sh -e

for filename in /usr/bin/virtualenv-2.7 /usr/bin/virtualenv-2.6 /usr/bin/virtualenv-2.5; do
	if [ -f $filename ]; then
		VIRTUALENV=$filename
		break
	fi
done
if [ -z $VIRTUALENV ]; then
	VIRTUALENV=/usr/bin/virtualenv
fi

chdir `dirname $0`
[ -d chardet -a \
  -d erlport -a \
  -f feedparser.py -a \
  ! -d env ] && exit 0
rm -rf env chardet erlport feedparser.py *.pyc

$VIRTUALENV env

env/bin/easy_install erlport
env/bin/easy_install https://github.com/kurtmckee/feedparser/tarball/master
env/bin/easy_install chardet

mv env/lib/*/site-packages/erlport-*/erlport .
mv env/lib/*/site-packages/feedparser-*/feedparser.py .
mv env/lib/*/site-packages/chardet-*/chardet .

patch feedparser.py << '_PATCH_'
--- feedparser.py.orig	2012-05-10 17:41:39.536888179 +0400
+++ feedparser.py	2012-05-10 17:39:06.364128637 +0400
@@ -3737,7 +3737,15 @@
     elif data[:4] == _l2bytes([0xff, 0xfe, 0x00, 0x00]):
         encoding = 'utf-32le'
         data = data[4:]
-    newdata = unicode(data, encoding)
+    try:
+        newdata = unicode(data, encoding)
+    except UnicodeDecodeError:
+        idata = unicode(data, encoding, 'ignore')
+        rdata = unicode(data, encoding, 'replace')
+        if len(rdata) - len(idata) < 32:
+            newdata = idata
+        else:
+            raise
     declmatch = re.compile('^<\?xml[^>]*?>')
     newdecl = '''<?xml version='1.0' encoding='utf-8'?>'''
     if declmatch.search(newdata):
_PATCH_

rm -rf env

python -m compileall .
