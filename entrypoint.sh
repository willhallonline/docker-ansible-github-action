#!/usr/bin/env bash
# Orchestrates running Ansible inside the willhallonline/docker-ansible image.
# Runs on the GitHub Actions runner (this is a composite action step), and
# shells out to `docker run` against the pinned container image.
set -euo pipefail

log() { printf '\n\033[1;34m[docker-ansible]\033[0m %s\n' "$1"; }
fail() { printf '\n\033[1;31m[docker-ansible] ERROR:\033[0m %s\n' "$1" >&2; exit 1; }

: "${INPUT_PLAYBOOK:?the 'playbook' input is required}"
WORKSPACE="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is not set - this action must run on a GitHub Actions runner}"

WORKDIR_INPUT="${INPUT_WORKING_DIRECTORY:-.}"
IMAGE_TAG="${INPUT_IMAGE_TAG:-latest}"
IMAGE="willhallonline/ansible:${IMAGE_TAG}"

command -v docker >/dev/null 2>&1 || fail "docker is required on the runner but was not found"

SECRETS_DIR="$(mktemp -d)"
cleanup() { rm -rf "${SECRETS_DIR}"; }
trap cleanup EXIT

DOCKER_ARGS=(--rm -v "${WORKSPACE}:/ansible" -w "/ansible/${WORKDIR_INPUT}")

if [[ "${INPUT_HOST_KEY_CHECKING:-true}" == "false" ]]; then
  DOCKER_ARGS+=(-e "ANSIBLE_HOST_KEY_CHECKING=False")
fi

PLAYBOOK_KEY_ARGS=()
if [[ -n "${INPUT_PRIVATE_KEY:-}" ]]; then
  printf '%s\n' "${INPUT_PRIVATE_KEY}" > "${SECRETS_DIR}/id_rsa"
  chmod 600 "${SECRETS_DIR}/id_rsa"
  DOCKER_ARGS+=(-v "${SECRETS_DIR}/id_rsa:/root/.ssh/id_rsa:ro")
  PLAYBOOK_KEY_ARGS+=(--private-key /root/.ssh/id_rsa)
fi

if [[ -n "${INPUT_KNOWN_HOSTS:-}" ]]; then
  printf '%s\n' "${INPUT_KNOWN_HOSTS}" > "${SECRETS_DIR}/known_hosts"
  chmod 600 "${SECRETS_DIR}/known_hosts"
  DOCKER_ARGS+=(-v "${SECRETS_DIR}/known_hosts:/root/.ssh/known_hosts:ro")
fi

VAULT_ARGS=()
if [[ -n "${INPUT_VAULT_PASSWORD:-}" ]]; then
  printf '%s' "${INPUT_VAULT_PASSWORD}" > "${SECRETS_DIR}/vault-password"
  chmod 600 "${SECRETS_DIR}/vault-password"
  DOCKER_ARGS+=(-v "${SECRETS_DIR}/vault-password:/run/secrets/vault-password:ro")
  VAULT_ARGS+=(--vault-password-file /run/secrets/vault-password)
elif [[ -n "${INPUT_VAULT_PASSWORD_FILE:-}" ]]; then
  VAULT_ARGS+=(--vault-password-file "${INPUT_VAULT_PASSWORD_FILE}")
fi

INVENTORY_ARGS=()
if [[ -n "${INPUT_INVENTORY:-}" ]]; then
  INVENTORY_ARGS+=(-i "${INPUT_INVENTORY}")
fi

EXTRA_VARS_ARGS=()
if [[ -n "${INPUT_EXTRA_VARS:-}" ]]; then
  EXTRA_VARS_ARGS+=(--extra-vars "${INPUT_EXTRA_VARS}")
fi

EXTRA_OPTIONS=()
if [[ -n "${INPUT_OPTIONS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_OPTIONS=(${INPUT_OPTIONS})
fi

GALAXY_OPTIONS=()
if [[ -n "${INPUT_GALAXY_OPTIONS:-}" ]]; then
  # shellcheck disable=SC2206
  GALAXY_OPTIONS=(${INPUT_GALAXY_OPTIONS})
fi

log "Pulling image ${IMAGE}"
docker pull --quiet "${IMAGE}" >/dev/null || fail "unable to pull ${IMAGE}"

if [[ -n "${INPUT_REQUIREMENTS:-}" ]]; then
  log "Installing requirements from ${INPUT_REQUIREMENTS}"
  docker run "${DOCKER_ARGS[@]}" "${IMAGE}" \
    ansible-galaxy install -r "${INPUT_REQUIREMENTS}" "${GALAXY_OPTIONS[@]}" \
    || fail "ansible-galaxy install failed"
fi

log "Running: ansible-playbook ${INPUT_PLAYBOOK}"
set +e
docker run "${DOCKER_ARGS[@]}" "${IMAGE}" \
  ansible-playbook "${INPUT_PLAYBOOK}" \
    "${INVENTORY_ARGS[@]}" \
    "${VAULT_ARGS[@]}" \
    "${PLAYBOOK_KEY_ARGS[@]}" \
    "${EXTRA_VARS_ARGS[@]}" \
    "${EXTRA_OPTIONS[@]}"
EXIT_CODE=$?
set -e

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "exit-code=${EXIT_CODE}" >> "${GITHUB_OUTPUT}"
fi

if [[ ${EXIT_CODE} -ne 0 ]]; then
  fail "ansible-playbook exited with code ${EXIT_CODE}"
fi

log "ansible-playbook completed successfully"
