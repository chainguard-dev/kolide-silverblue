# Kolide for Exotic Linux Environments

This script rebuilds [Kolide](https://www.kolide.com/) Linux packages for deployment within Exotic Linux Environments such as:

* arm64 (deb, rpm, apk, pacman)
* Fedora Universal Blue [SilverBlue, Bluefin, etc] (rpm)
* Chainguard OS, Wolfi [apk]

This tool works by:

* Extracting the per-user and domain configuration out of `/etc/kolide-k2/secrets` held within the Kolide-generated RPM
* Patches Kolide and its dependencies to support alternative Linux environments.
* Builds a fresh Kolide launcher package just for you

## Usage

### Kolide on Slack

1. Contact the @Kolide bot on Slack
2. Click `Enroll your device`
3. For the `Choose an installation package` dialog, select `Linux (rpm)`
4. Download the RPM that the Kolide bot generates for you.
5. Run `./rebuild.sh /path/to/downloaded.rpm`
6. Follow the instructions to install the resulting rebuilt package

### Kolide Device Trust

1. Login to a website protected by Kolide Device Trust
3. When prompted to "Install Kolide to complete verification", click `CentOS (kolide.rpm)`
5. Run `./rebuild.sh /path/to/downloaded.rpm`
6. Follow the instructions to install the resulting rebuilt package

## Requirements

- Go v1.21 or higher to [rebuild the launcher](https://github.com/kolide/launcher/blob/main/docs/launcher.md)
- Podman or Docker
- GNU patch
- GNU make
- rpm2cpio (to process RPM files)

## Future work

- Upstreaming all patches
- Cloud Run application to streamline the conversion process
