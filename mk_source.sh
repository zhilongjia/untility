#! /bin/bash
#mv ~/*.deb /media/DEB
dpkg-scanpackages DEB /dev/null |gzip >DEB/Packages.gz
apt-get update
