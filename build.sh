#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${BASE_DIR}/build"
PICO_SDK_DIR="${BASE_DIR}/pico-sdk"

BOARD="${1:-pico}"
shift || true
EXTRA_CMAKE_ARGS=("$@")

ensure_sdk() {
	if [ -d "${BASE_DIR}/.git" ] && [ ! -e "${PICO_SDK_DIR}/.git" ]; then
		git -C "${BASE_DIR}" submodule update --init --recursive
	elif [ ! -d "${PICO_SDK_DIR}" ]; then
		echo "Missing pico-sdk checkout; clone the submodule first."
		exit 1
	fi

	if [ ! -f "${PICO_SDK_DIR}/pico_sdk_init.cmake" ]; then
		echo "pico-sdk checkout looks incomplete."
		exit 1
	fi

	if [[ "${BOARD}" == pico2* ]]; then
		local sdk_major
		sdk_major="$(sed -n 's/^ *set(PICO_SDK_VERSION_MAJOR[[:space:]]*\\([0-9]\\+\\).*/\\1/p' "${PICO_SDK_DIR}/pico_sdk_version.cmake")"
		if [ -n "${sdk_major}" ] && [ "${sdk_major}" -lt 2 ]; then
			echo "Pico 2 builds require Pico SDK >= 2.0. Update pico-sdk (e.g. checkout tag 2.2.0) before building." >&2
			exit 1
		fi
	fi
}

configure() {
	local build_dir="${BUILD_ROOT}/${BOARD}"
	cmake -B "${build_dir}" -S "${BASE_DIR}" -DPICO_BOARD="${BOARD}" "${EXTRA_CMAKE_ARGS[@]}"
}

build() {
	cmake --build "${BUILD_ROOT}/${BOARD}"
}

main() {
	ensure_sdk
	configure
	build
}

main "$@"
