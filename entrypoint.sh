#!/bin/sh
set -eu

if [ -z "${INPUT_PLAYBOOK:-}" ]; then
  echo "Input 'playbook' is required."
  exit 1
fi

inventory="${INPUT_INVENTORY:-inventory}"
extra_args="${INPUT_EXTRA_ARGS:-}"

case "${inventory}" in
  *".."* | *$'\n'* | *$'\r'*)
    echo "Input 'inventory' contains invalid path content."
    exit 1
    ;;
esac

if [ -n "${extra_args}" ] && printf '%s' "${extra_args}" | grep -Eq '[^A-Za-z0-9_.,:/=+@% -]'; then
  echo "Input 'extra-args' contains unsupported characters."
  exit 1
fi

set -f
set --
if [ -n "${extra_args}" ]; then
  # split extra args on whitespace into positional parameters
  # shellcheck disable=SC2086
  set -- ${extra_args}
fi

if ansible-playbook -i "${inventory}" "$@" "${INPUT_PLAYBOOK}"; then
  echo "result=success" >>"${GITHUB_OUTPUT}"
else
  echo "result=failure" >>"${GITHUB_OUTPUT}"
  exit 1
fi
