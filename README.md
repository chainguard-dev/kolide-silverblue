# Kolide for Exotic Linux Environments

This script rebuilds [Kolide](https://www.kolide.com/) Linux packages for deployment within Exotic Linux Environments such as:

* arm64 (deb, rpm, apk, pacman)
* Fedora SilverBlue & Bluefin (rpm)
* Chainguard OS, Wolfi (apk)

The following distributions will likely work, but are untested:

* Bazzite (rpm)
* VanillaOS (deb)

These environments are known to need further work:

* Alpine Linux (apk) - fails due to osqueryd glibc dependency (_nl_msg_cat_cntr): symbol not found
* RISC-V -

## Requirements

- Go v1.21 or higher to [rebuild the launcher](https://github.com/kolide/launcher/blob/main/docs/launcher.md)
- Podman or Docker
- GNU patch
- GNU make
- rpm2cpio (to process RPM files)

## Usage

1. Download an officially supported Kolide Linux RPM package from a trusted source (Slack, Device Trust)
2. Run `./rebuild.sh </path/to/rpm>`
3. Install resulting package

It's necessary to provide an official Kolide package as it contains the enrollment secret necessary for your environment.
