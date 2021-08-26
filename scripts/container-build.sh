#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2019 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software 
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Identify the script location, to reach, for example, the helper scripts.

build_script_path="$0"
if [[ "${build_script_path}" != /* ]]
then
  # Make relative path absolute.
  build_script_path="$(pwd)/$0"
fi

script_folder_path="$(dirname "${build_script_path}")"
script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

helper_folder_path="${script_folder_path}/helper"

# -----------------------------------------------------------------------------

# Inner script to run inside Docker containers to build the 
# xPack OpenOCD distribution packages.

# For native builds, it runs on the host (macOS build cases,
# and development builds for GNU/Linux).

# -----------------------------------------------------------------------------

defines_script_path="${script_folder_path}/defs-source.sh"
echo "Definitions source script: \"${defines_script_path}\"."
source "${defines_script_path}"

# This file is generated by the host build script.
host_defines_script_path="${script_folder_path}/host-defs-source.sh"
echo "Host definitions source script: \"${host_defines_script_path}\"."
source "${host_defines_script_path}"

helper_common_functions_script_path="${helper_folder_path}/common-functions-source.sh"
echo "Common helper functions source script: \"${helper_common_functions_script_path}\"."
source "${helper_common_functions_script_path}"

helper_common_libs_functions_script_path="${helper_folder_path}/common-libs-functions-source.sh"
echo "Common helper libs functions source script: \"${helper_common_libs_functions_script_path}\"."
source "${helper_common_libs_functions_script_path}"

common_functions_script_path="${script_folder_path}/common-functions-source.sh"
echo "Common functions source script: \"${common_functions_script_path}\"."
source "${common_functions_script_path}"

common_versions_script_path="${script_folder_path}/common-versions-source.sh"
echo "Common versions source script: \"${common_versions_script_path}\"."
source "${common_versions_script_path}"

helper_container_functions_script_path="${helper_folder_path}/container-functions-source.sh"
echo "Container helper functions source script: \"${helper_container_functions_script_path}\"."
source "${helper_container_functions_script_path}"

helper_common_libs_functions_script_path="${helper_folder_path}/common-libs-functions-source.sh"
echo "Common helper libs functions source script: \"${helper_common_libs_functions_script_path}\"."
source "${helper_common_libs_functions_script_path}"

helper_common_apps_functions_script_path="${helper_folder_path}/common-apps-functions-source.sh"
echo "Common helper apps functions source script: \"${helper_common_apps_functions_script_path}\"."
source "${helper_common_apps_functions_script_path}"

container_libs_functions_script_path="${script_folder_path}/${COMMON_LIBS_FUNCTIONS_SCRIPT_NAME}"
echo "Container libs functions source script: \"${container_libs_functions_script_path}\"."
source "${container_libs_functions_script_path}"

container_app_functions_script_path="${script_folder_path}/${COMMON_APPS_FUNCTIONS_SCRIPT_NAME}"
echo "Container app functions source script: \"${container_app_functions_script_path}\"."
source "${container_app_functions_script_path}"

# -----------------------------------------------------------------------------

if [ ! -z "#{DEBUG}" ]
then
  echo "$@"
fi

WITH_STRIP="y"
WITH_PDF="y"
WITH_HTML="n"
IS_DEVELOP=""
IS_DEBUG=""
WITH_TESTS="y"
LINUX_INSTALL_RELATIVE_PATH=""

if [ "$(uname)" == "Linux" ]
then
  JOBS="$(nproc)"
elif [ "$(uname)" == "Darwin" ]
then
  JOBS="$(sysctl hw.ncpu | sed 's/hw.ncpu: //')"
else
  JOBS="1"
fi

while [ $# -gt 0 ]
do

  case "$1" in

    --disable-strip)
      WITH_STRIP="n"
      shift
      ;;

    --disable-tests)
      WITH_TESTS="n"
      shift
      ;;

    --without-pdf)
      WITH_PDF="n"
      shift
      ;;

    --with-pdf)
      WITH_PDF="y"
      shift
      ;;

    --without-html)
      WITH_HTML="n"
      shift
      ;;

    --with-html)
      WITH_HTML="y"
      shift
      ;;

    --jobs)
      JOBS=$2
      shift 2
      ;;

    --develop)
      IS_DEVELOP="y"
      shift
      ;;

    --debug)
      IS_DEBUG="y"
      shift
      ;;

    --linux-install-relative-path)
      LINUX_INSTALL_RELATIVE_PATH="$2"
      shift 2
      ;;

    *)
      echo "Unknown action/option $1"
      exit 1
      ;;

  esac

done

if [ "${IS_DEBUG}" == "y" ]
then
  WITH_STRIP="n"
fi

# -----------------------------------------------------------------------------

start_timer

detect_container

prepare_xbb_env

prepare_xbb_extras

# -----------------------------------------------------------------------------

echo
echo "Here we go..."
echo

build_versions

# -----------------------------------------------------------------------------

copy_distro_files

check_binaries

create_archive

# Change ownership to non-root Linux user.
fix_ownership

# -----------------------------------------------------------------------------

stop_timer

exit 0

# -----------------------------------------------------------------------------
