#!/bin/bash

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
sed -i "s/^Name:.*$/Name: aps-nginx/" aps-nginx.spec
sed -i "s/%{name}/nginx/" aps-nginx.spec
sed -i "s/^Source0:.*$/Source0: https:\/\/nginx.org\/download\/nginx-%{version}.tar.gz/" aps-nginx.spec
sed -i "s/%autosetup -p1/%autosetup -p1 -n nginx-%{version}/" aps-nginx.spec
sed -i 's/mv ..\/nginx-%{version}-%{release}-src ./mv ..\/%{name}-%{version}-%{release}-src ./g' aps-nginx.spec
sed -i 's/mv nginx-%{version}-%{release}-src %{buildroot}%{nginx_srcdir}/mv %{name}-%{version}-%{release}-src %{buildroot}%{nginx_srcdir}/g' aps-nginx.spec
echo "Provides: aps-nginx = %{nginx_abiversion}" aps-nginx.spec
echo "Conflicts: nginx" >> aps-nginx.spec

# exit 0

printf "Repackaging $LATEST_VERSION...\n"
rm -rf ~/rpmbuild/
rpmdev-setuptree || exit 1

cp aps-nginx.spec ~/rpmbuild/SPECS/aps-nginx.spec
mv * ~/rpmbuild/SOURCES

rpmbuild -bs ~/rpmbuild/SPECS/aps-nginx.spec || exit 1
cp -r ~/rpmbuild/SRPMS/* . || exit 1
printf "Building RPM...\n"
rpmbuild -bb ~/rpmbuild/SPECS/aps-nginx.spec || exit 1
cp -r ~/rpmbuild/RPMS/* .

popd
printf "✅ Done.\n"
