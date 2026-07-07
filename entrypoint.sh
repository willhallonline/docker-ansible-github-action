#!/bin/sh
set -eu

if [ -z "${INPUT_PLAYBOOK:-}" ]; then
  echo "Input 'playbook' is required."
  exit 1
fi

inventory="${INPUT_INVENTORY:-inventory}"
extra_args="${INPUT_EXTRA_ARGS:-}"
workspace="${GITHUB_WORKSPACE:-$(pwd)}"

case "${inventory}" in
  # defense in depth: quick pattern block before canonical workspace validation below
  ".." | "../"* | *"/../"* | *"/.." | /* | "~"* | *$'\n'* | *$'\r'*)
    echo "Input 'inventory' contains invalid path content."
    exit 1
    ;;
esac

case "${extra_args}" in
  *" "* | *$'\t'* | *$'\n'* | *$'\r'*)
    echo "Input 'extra-args' must not contain whitespace characters."
    exit 1
    ;;
esac

case "${inventory}" in
  *,*) : ;;
  *)
    resolved_inventory="$(realpath -m "${inventory}")"
    resolved_workspace="$(realpath -m "${workspace}")"
    case "${resolved_inventory}" in
      "${resolved_workspace}" | "${resolved_workspace}"/*) : ;;
      *)
        echo "Inventory file or path '${inventory}' must be inside the workspace."
        exit 1
        ;;
    esac
    if [ ! -e "${inventory}" ]; then
      echo "Inventory path '${inventory}' was not found."
      exit 1
    fi
    ;;
esac

ansible_cmd_status=0
if [ -n "${extra_args}" ]; then
  ansible-playbook -i "${inventory}" "${extra_args}" "${INPUT_PLAYBOOK}" || ansible_cmd_status=$?
else
  ansible-playbook -i "${inventory}" "${INPUT_PLAYBOOK}" || ansible_cmd_status=$?
fi

if [ "${ansible_cmd_status}" -eq 0 ]; then
  echo "result=success" >>"${GITHUB_OUTPUT}"
else
  echo "result=failure" >>"${GITHUB_OUTPUT}"
  exit 1
fi
