# docker-ansible-github-action

A Docker-based GitHub Action framework for running Ansible playbooks.

## Usage

```yaml
- name: Run playbook
  uses: willhallonline/docker-ansible-github-action@v1
  with:
    playbook: ./site.yml
    inventory: ./inventory
    extra-args: -vv
```

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `playbook` | Yes | _none_ | Path to the Ansible playbook to run |
| `inventory` | No | `inventory` | Inventory file/path passed to `ansible-playbook -i` |
| `extra-args` | No | `""` | Additional arguments for `ansible-playbook` (plain args only; shell metacharacters are rejected) |

## Outputs

| Name | Description |
| --- | --- |
| `result` | Result of the `ansible-playbook` execution |
