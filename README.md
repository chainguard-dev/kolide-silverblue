# kolide-silverblue

This script rebuilds a (Kolide)[https://www.kolide.com/] RPM for deployment on Fedora Silverblue.

## Usage

1. Get the @Kolide bot to send you an RPM via Slack
2. Run `./rebuild.sh <path to RPM>
3. Install RPM using `sudo rpm-ostree install launcher.linux-systemd-rpm.rpm`

## How it works

This script automates the following steps:

1. Checks out https://github.com/kolide/launcher
2. Installs Fedora Silverblue Patches to:
  - Add --bin_root_dir flag
  - Add podman support
3. Extracts configuration details from the RPM you provided
4. Builds a new RPM
