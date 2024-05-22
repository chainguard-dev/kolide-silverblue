#!/bin/bash
#
# rebuilds a Fedora Red Hat Linux RPM for Fedora Silverbluea
#
# usage:
#   ./rebuild.sh zxkx_whatever.rpm
#
# need help debugging? try sh -x ./rebuild.sh <path to RPM>

set -eu -o pipefail
if [[ $# != 1 ]]; then
  echo "usage: ./rebuild.sh <path to original RPM>"
  exit 1
fi

readonly REFERENCE_RPM=$1
readonly WORK_DIR=$(pwd)/work

if ! go version; then
  echo "you must first install go ..."
fi

mkdir -p work/extract
cd work/extract
echo ">> extracting ${REFERENCE_RPM} ..."
rpm2cpio "${REFERENCE_RPM}" | cpio -idmv

echo ""
echo ">> parsing install flags ..."
readonly FLAG_HOSTNAME=$(grep ^hostname etc/kolide-k2/launcher.flags | cut -d" " -f2)
readonly FLAG_TRANSPORT=$(grep ^transport etc/kolide-k2/launcher.flags | cut -d" " -f2)
readonly SECRET=$(cat etc/kolide-k2/secret)

cd "${WORK_DIR}"
if [[ ! -d "launcher" ]]; then
  echo ""
  echo ">> downloading launcher source ..."
  git clone https://github.com/kolide/launcher.git launcher
fi

echo ""
echo ">> updating launcher ..."
cd launcher
git stash
git pull

echo ""
echo ">> grabbing launcher patches ..."
cd "${WORK_DIR}"
test -f 1722.diff || curl -LO https://patch-diff.githubusercontent.com/raw/kolide/launcher/pull/1722.diff
test -f 1721.diff || curl -LO https://patch-diff.githubusercontent.com/raw/kolide/launcher/pull/1721.diff

echo ""
echo ">> patching launcher ..."
cd launcher
patch -p1 < ../1722.diff
patch -p1 < ../1721.diff

echo ""
echo ">> building package-builder ..."
make package-builder

echo ""
echo ">> building install package with podman ..."
./build/package-builder make \
    --i-am-a-kolide-customer \
    -hostname "${FLAG_HOSTNAME}" \
    -enroll_secret "${SECRET}" \
    -identifier kolide-k2 \
    -output_dir out \
    -transport "${FLAG_TRANSPORT}" \
    -with_initial_runner \
    -targets linux-systemd-rpm \
    -bin_root_dir=/opt \
    -container_tool=podman

dest="${WORK_DIR}/$(basename ${REFERENCE_RPM})"
mv out/launcher.linux-systemd-rpm.rpm "${dest}"
ls -lad "${dest}"

echo ""
echo ">> SUCCESS! ${dest}"
echo ""
echo "To install, use:"
echo ""
echo "sudo rpm-ostree install ${dest}"
echo "sudo reboot"
echo "sudo systemctl enable launcher.kolide-k2"
echo "sudo systemctl start launcher.kolide-k2"
