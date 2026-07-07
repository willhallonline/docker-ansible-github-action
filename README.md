# docker-ansible-github-action

A GitHub Action that runs `ansible-playbook` inside the [willhallonline/docker-ansible](https://github.com/willhallonline/docker-ansible) container images ([Docker Hub](https://hub.docker.com/r/willhallonline/ansible)), so your CI runs the exact same Ansible environment as your local `docker run willhallonline/ansible ...` workflow.

This is a **composite action**: it doesn't rebuild a container image itself, it pulls the `willhallonline/ansible` image (any tag you choose) and runs it via `docker run` on the GitHub-hosted runner, mounting your checked-out repo. This keeps runs fast (image layers are cached) and lets you pin any Ansible/OS combination published by that project.

## Usage

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  ansible:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run playbook
        uses: willhallonline/docker-ansible-github-action@v1
        with:
          playbook: playbooks/site.yml
          inventory: inventory/production.ini
          private-key: ${{ secrets.SSH_PRIVATE_KEY }}
          host-key-checking: 'false'
          extra-vars: 'env=production'
          image-tag: 'latest'
```

### With Ansible Vault and Galaxy requirements

```yaml
      - name: Run playbook
        uses: willhallonline/docker-ansible-github-action@v1
        with:
          playbook: site.yml
          inventory: inventory/production.ini
          requirements: requirements.yml
          vault-password: ${{ secrets.ANSIBLE_VAULT_PASSWORD }}
          private-key: ${{ secrets.SSH_PRIVATE_KEY }}
          known-hosts: ${{ secrets.KNOWN_HOSTS }}
          extra-vars: '@vars/production.yml'
          options: '--limit production -vv'
          image-tag: '2.21-alpine-3.22'
```

## Inputs

| Name                  | Required | Default    | Description                                                                                                    |
|-----------------------|----------|------------|------------------------------------------------------------------------------------------------------------------|
| `playbook`            | yes      |            | Path to the Ansible playbook, relative to `working-directory`.                                                  |
| `inventory`            | no       | `''`       | Path to the inventory file or directory, relative to `working-directory`.                                       |
| `working-directory`    | no       | `.`        | Directory (relative to the workspace root) to run `ansible-playbook` from.                                      |
| `requirements`         | no       | `''`       | Path to a `requirements.yml` (roles/collections) installed via `ansible-galaxy install` before the playbook runs.|
| `galaxy-options`       | no       | `''`       | Extra arguments appended to `ansible-galaxy install`.                                                           |
| `vault-password`       | no       | `''`       | Ansible Vault password (plaintext). Written to a temp file on the runner and passed as `--vault-password-file`. Pass via a secret. |
| `vault-password-file`  | no       | `''`       | Path to an existing vault password file, used if `vault-password` is not set.                                   |
| `private-key`          | no       | `''`       | SSH private key (PEM contents) for connecting to managed hosts. Written to a temp file (mode `600`). Pass via a secret. |
| `host-key-checking`    | no       | `true`     | Set to `false` to disable SSH host key checking (useful for ephemeral/cloud hosts).                             |
| `known-hosts`          | no       | `''`       | Additional `known_hosts` entries to trust before connecting.                                                    |
| `extra-vars`           | no       | `''`       | Value passed to `--extra-vars` (`@file.yml`, `key=value`, or a JSON string).                                    |
| `options`              | no       | `''`       | Additional raw, space-separated arguments appended to `ansible-playbook` (e.g. `-vvv --check --limit staging`). |
| `image-tag`            | no       | `latest`   | Tag of the `willhallonline/ansible` image to use. See [available tags](https://hub.docker.com/r/willhallonline/ansible/tags). |

## Outputs

| Name        | Description                              |
|-------------|-------------------------------------------|
| `exit-code` | Exit code returned by `ansible-playbook`. |

## How it works

1. The action pulls `willhallonline/ansible:<image-tag>`.
2. If `requirements` is set, it runs `ansible-galaxy install -r <requirements>` inside the container.
3. It runs `ansible-playbook <playbook>` inside the container, with your repo mounted at `/ansible` (working directory `/ansible/<working-directory>`), forwarding `inventory`, `extra-vars`, vault password, private key, and any extra `options`.
4. Secrets (`private-key`, `vault-password`, `known-hosts`) are written to a temporary directory on the runner (not the repo), mounted read-only into the container, and removed after the run.

See [`examples/`](examples) for a minimal playbook/inventory used by this repo's own CI smoke test, and the upstream [docker-ansible README](https://github.com/willhallonline/docker-ansible#readme) for the full list of supported image tags and included Ansible versions.

## License

See [LICENSE](LICENSE).
