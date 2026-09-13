# Changelog

## v1.1.0

- Support the non-root `ansible` user used by the current `willhallonline/ansible` images.
- Mount SSH private keys and `known_hosts` under `/home/ansible/.ssh`.
- Update the pinned smoke test and documentation example to Alpine 3.24, available in `docker-ansible` v6.4.9.

## v1.0.0

- Initial release of the Docker Ansible GitHub Action.
