# AP Sensing nginx

A script for repackaging the nginx rpm package with a custom `nginx.conf`.

##  Requirements

```bash
sudo dnf install rpmdevtools sed curl wget tar gcc make
```

## Building

```bash
./build_rpm.sh
```

The resulting rpm files are the located inside `build`.

## Signing

Follow these steps for signing the build rpm packages.

### Requirements

```bash
sudo dnf install rpm-sign
```

Follow these instructions for setting up a signing gpg key: https://access.redhat.com/articles/3359321
Then run the following commands for signing all (source-)rpms.
```bash
rpm --addsign build/**/*.rpm
```