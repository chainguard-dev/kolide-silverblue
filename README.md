# Kolide for Exotic Linux Environments

This script rebuilds [Kolide](https://www.kolide.com/) Linux packages for deployment within Exotic
Linux Environments such as:

* Anything on arm64
* Fedora SilverBlue

## Requirements

- Go v1.21 or higher to [rebuild the launcher](https://github.com/kolide/launcher/blob/main/docs/launcher.md)
- podman or docker
- GNU `patch`

## Usage

1. Download an officially supported Kolide Linux package from a trusted source (Slack, Device Trust)
2. Run `./rebuild.sh </path/to/pkg>
3. Install resulting package

It's necessary to provide an official Kolide package as it contains the enrollment secret necessary for your environment.
