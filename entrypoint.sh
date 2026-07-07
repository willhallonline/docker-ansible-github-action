#!/bin/sh
set -eu

if [ -z "${INPUT_PLAYBOOK:-}" ]; then
  echo "Input 'playbook' is required."
  exit 1
fi

inventory="${INPUT_INVENTORY:-inventory}"
extra_args="${INPUT_EXTRA_ARGS:-}"

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
