#!/bin/bash

set -ue pipefail

NGINX_SRPM_URL=https://dl.fedoraproject.org/pub/fedora/linux/releases/38/Everything/source/tree/Packages/n
BUILD_DIR=build

printf "Preparing build environment...\n"
mkdir -p $BUILD_DIR
rm -rf $BUILD_DIR/*
pushd $BUILD_DIR

LATEST_VERSION=$(curl -L -s $NGINX_SRPM_URL | grep -oE 'href="(nginx-[0-9].+)([^"]+).src.rpm"' | awk -F'"' '{print $2}' | sort -V | tail -n 1)

printf "Downloading $LATEST_VERSION...\n"
wget $NGINX_SRPM_URL/$LATEST_VERSION || exit 1

printf "Extracting $LATEST_VERSION...\n"
rpm2cpio $LATEST_VERSION | cpio -idmv || exit 1
rm $LATEST_VERSION

printf "Patching $LATEST_VERSION...\n"

# Patch nginx.conf
rm -f nginx.conf
cp ../nginx.conf .

# Patch nginx.spec
cp nginx.spec aps-nginx.spec
patch -p1 < ../aps-nginx.spec.diff

# Mark all configs to be replaced by future updates
sed -i 's/%config(noreplace)/%config/g' aps-nginx.spec

printf "Repackaging $LATEST_VERSION...\n"
rm -rf ~/rpmbuild/
rpmdev-setuptree || exit 1

cp aps-nginx.spec ~/rpmbuild/SPECS/aps-nginx.spec
mv * ~/rpmbuild/SOURCES
cp ../proxy_shared.conf ~/rpmbuild/SOURCES/proxy_shared.conf

rpmbuild -bs ~/rpmbuild/SPECS/aps-nginx.spec || exit 1
cp -r ~/rpmbuild/SRPMS/* . || exit 1
printf "Building RPM...\n"
rpmbuild -bb ~/rpmbuild/SPECS/aps-nginx.spec || exit 1
cp -r ~/rpmbuild/RPMS/* .

popd
printf "✅ Done.\n"
