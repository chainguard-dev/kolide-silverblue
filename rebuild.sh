#!/bin/bash
#
# Rebuilds a Kolide launcher for the current Linux distribution.
#
# usage:
#   ./rebuild.sh zxkx_whatever.rpm
#
# need help debugging? try sh -x ./rebuild.sh <path to RPM>

if [[ $# != 1 ]]; then
	echo "usage: ./rebuild.sh <path to original package>"
	exit 1
fi

function check_prereqs() {
	missing=0
	if ! type -P go >/dev/null; then
		echo "- go command missing"
		missing=1
	fi

	if ! type -P patch >/dev/null; then
		echo "- patch command missing"
		missing=1
	fi

	if ! type -P make >/dev/null; then
		echo "- make command missing"
		missing=1
	fi

	if ! type -P git >/dev/null; then
		echo "- git command missing"
		missing=1
	fi

	if ! type -P rpm2cpio >/dev/null; then
		echo "- rpm2cpio command missing"
		missing=1
	fi

	if ! type -P ${CONTAINER_TOOL} >/dev/null; then
		echo "- container build tool (podman, docker) missing"
		missing=1
	elif [[ "${CONTAINER_TOOL}" == "docker" ]]; then
		if ! groups | grep -q docker; then
			echo "- user must be in the 'docker' group: run 'newgrp docker'"
			missing=1
		fi
	fi

	if [[ "${missing}" == 1 ]]; then
		echo ""
		echo "*** exiting due to unmet dependencies"
		exit 2
	fi
}

function extract_flags_rpm() {
	mkdir -p extract
	pushd extract

	echo ">> extracting ${REFERENCE_PKG} ..."
	rpm2cpio "${REFERENCE_PKG}" | cpio -idmv

	echo ""
	echo ">> parsing install flags ..."
	readonly FLAG_HOSTNAME=$(grep ^hostname etc/kolide-k2/launcher.flags | cut -d" " -f2)
	readonly FLAG_TRANSPORT=$(grep ^transport etc/kolide-k2/launcher.flags | cut -d" " -f2)
	readonly SECRET=$(cat etc/kolide-k2/secret)
	popd
}

function extract_flags_deb() {
	mkdir -p extract
	pushd extract

	echo ">> extracting ${REFERENCE_PKG} ..."
	rpm2cpio "${REFERENCE_PKG}" | cpio -idmv

	echo ""
	echo ">> parsing install flags ..."
	readonly FLAG_HOSTNAME=$(grep ^hostname etc/kolide-k2/launcher.flags | cut -d" " -f2)
	readonly FLAG_TRANSPORT=$(grep ^transport etc/kolide-k2/launcher.flags | cut -d" " -f2)
	readonly SECRET=$(cat etc/kolide-k2/secret)
	popd
}

function build_package_builder() {
	if [[ ! -d "launcher" ]]; then
		echo ""
		echo ">> downloading launcher source ..."
		git clone https://github.com/kolide/launcher.git launcher
	fi

	echo ""
	echo ">> updating launcher ..."
	pushd launcher
	git stash
	git pull

	for path in "${SRC_DIR}"/patches/launcher/*; do
		echo ">> applying patch: ${path} ..."
		patch -p1 <"${path}"
	done

	echo ""
	echo ">> building package-builder ..."
	env GOTOOLCHAIN=auto make package-builder
	popd
}

function build_fpm() {
	# unnecessary
	if [[ "${ARCH}" == "x86_64" ]]; then
		return
	fi

	if "${CONTAINER_TOOL}" images -f 'reference=kolide/fpm' --format '{{.CreatedSince}}' | grep -q minutes; then
		echo ">> found existing local fpm package ..."
		return
	fi

	if [[ ! -d "fpm" ]]; then
		echo ""
		echo ">> downloading fpm source ..."
		git clone https://github.com/jordansissel/fpm.git fpm
	fi

	echo ""
	echo ">> updating fpm ..."
	pushd fpm
	git stash
	git pull

	for path in "${SRC_DIR}"/patches/fpm/*; do
		echo ">> applying patch: ${path} ..."
		patch -p1 <"${path}"
	done

	make -e TAG=docker.io/kolide/fpm -e BUILDER="${CONTAINER_TOOL}" docker-release-everything
	popd
}

function build_launcher_package() {
	local extra_flags=" -container_tool=${CONTAINER_TOOL}"
	if [[ "${DISTRO}" == "silverblue" ]]; then
		extra_flags="${extra_flags} -bin_root_dir=/opt"
	fi

	local init="systemd"

	local platform="${ARCH}"
	case "${ARCH}" in
	aarch64)
		platform="arm64"
		;;
	x86_64)
		platform="amd64"
		;;
	esac
	echo ""
	echo ">> building install package with ${extra_flags} ..."
	pushd launcher

	local format="${PKG_FORMAT}"
	local target="linux-${platform}-${init}-${format}"
	echo ">> target: ${target}"

	./build/package-builder make \
		--i-am-a-kolide-customer \
		-hostname "${FLAG_HOSTNAME}" \
		-enroll_secret "${SECRET}" \
		-identifier kolide-k2 \
		-output_dir out \
		-transport "${FLAG_TRANSPORT}" \
		-with_initial_runner \
		-debug \
		-targets "${target}" ${extra_flags}

	output=$(echo "out/launcher.${target}.${format}" | sed -e s/-amd64//)
	dest="${WORK_DIR}/$(basename ${REFERENCE_PKG} | sed -e s/\.rpm//).${format}"

	mv "${output}" "${dest}"
	ls -lad "${dest}"

	echo ""
	echo ">> SUCCESS! ${dest}"
	echo ""

	case "${DISTRO}" in
	silverblue | bazzite | bluefin)
		echo "To install, run:"
		echo ""
		echo "rpm-ostree install ${dest}"
		echo "sudo rpm-ostree apply-live --allow-replacement"
		echo "systemctl enable --now launcher.kolide-k2"
		echo ""
		echo "To uninstall, use:"
		echo ""
		echo "sudo rpm-ostree uninstall launcher-kolide-k2"
		;;
	fedora | rocky | "red hat")
		echo "To install, run:"
		echo ""
		echo "sudo rpm -ivh ${dest}"
		;;
	debian | ubuntu | vanillaos)
		echo "To install, run:"
		echo ""
		echo "sudo dpkg -i ${dest}"
		;;
	esac
}

set -eu -o pipefail

if [[ ! -e "${1}" ]]; then
	echo "$1 does not exist"
	exit 2
fi

readonly SRC_DIR="$(dirname $(realpath $0))"
readonly REFERENCE_PKG="$(realpath "$1")"
readonly WORK_DIR=/tmp/rebuild_$(basename ${REFERENCE_PKG})
readonly DISTRO=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }' | sed s/\"//g)
readonly ARCH=$(uname -m)
if type -P podman >/dev/null; then
	readonly CONTAINER_TOOL="podman"
else
	readonly CONTAINER_TOOL="docker"
fi

if type -P apt-get >/dev/null; then
	readonly PKG_FORMAT="deb"
elif type -P pacman >/dev/null; then
	readonly PKG_FORMAT="pacman"
elif type -P rpm >/dev/null; then
	readonly PKG_FORMAT="rpm"
elif type -P apk >/dev/null; then
	readonly PKG_FORMAT="apk"
fi

echo "#######################################################"
echo "## Kolide ELE (Exotic Linux Environment), building for:"
echo "##   DISTRO:         ${DISTRO}"
echo "##   ARCH:           ${ARCH}"
echo "##   FORMAT:         ${PKG_FORMAT}"
echo "##   CONTAINER TOOL: ${CONTAINER_TOOL}"
echo "#######################################################"
echo ""
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"
check_prereqs
extract_flags_rpm
build_package_builder
build_fpm
build_launcher_package
