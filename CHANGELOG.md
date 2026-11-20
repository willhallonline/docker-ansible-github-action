# Changelog

## v1.1.2

- Update deployment documentation and smoke tests to the current `2.22-alpine-3.24` image.
- Clarify that exact versioned image tags are recommended for reproducible deployments.

## v1.1.1

- Retry transient Docker image pulls before failing.
- Refresh the Docker Ansible documentation link and pinned image reference.

## v1.1.0

- Support the non-root `ansible` user used by the current `willhallonline/ansible` images.
- Mount SSH private keys and `known_hosts` under `/home/ansible/.ssh`.
- Update the pinned smoke test and documentation example to Alpine 3.24, available in `docker-ansible` v6.4.9.

## v1.0.0

- Initial release of the Docker Ansible GitHub Action.
