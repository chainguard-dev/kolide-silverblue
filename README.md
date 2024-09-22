# kolide-silverblue

This script rebuilds a [Kolide](https://www.kolide.com/) RPM for deployment on Fedora Silverblue.

## Requirements

- Go v1.21 or higher to [rebuild the launcher](https://github.com/kolide/launcher/blob/main/docs/launcher.md)
- podman or docker

## Usage

1. Talk to the @Kolide Slack bot to
1. "Enroll a Device" via the @Kolide Slack bot, selecting the `RPM Linux (.rpm)` installation package.
2. Download the RPM file that @Kolide sends via Slack
2. Run `./rebuild.sh <path to downloaded RPM>`
3. Get coffee while the script runs

### RPM installation instructions

To install the resulting RPM on Fedora SilverBlue, run:

```
rpm-ostree install </path/to/kolide-launcher.rpm>
sudo rpm-ostree apply-live
systemctl enable --now launcher.kolide-k2
```

To uninstall the custom package, run:

```
sudo rpm-ostree uninstall launcher-kolide-k2
```

## How it works

This script automates the following steps:

1. Checks out https://github.com/kolide/launcher
2. Patches launcher with:
  - https://github.com/kolide/launcher/pull/1721
  - https://github.com/kolide/launcher/pull/1722
3. Extracts configuration details from the RPM you provided
4. Builds a new RPM

## Caveats

Autoupdates are not enabled, as this may result in Kolide sending you an incompatible launcher in the future. Hopefully Kolide will natively support Fedora SilverBlue soon so that this hack is unnecessary in the near future.

Be sure to mention to Kolide's support team that you would like native support for immutable Linux distrubitons such as Fedora SilverBlue!
