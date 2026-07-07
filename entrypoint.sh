#!/bin/sh
set -eu

if [ -z "${INPUT_PLAYBOOK:-}" ]; then
  echo "Input 'playbook' is required."
  exit 1
fi

inventory="${INPUT_INVENTORY:-inventory}"
extra_args="${INPUT_EXTRA_ARGS:-}"

ansible-playbook -i "${inventory}" ${extra_args} "${INPUT_PLAYBOOK}"
echo "result=success" >>"${GITHUB_OUTPUT}"
