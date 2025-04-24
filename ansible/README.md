# Local setup

Our setup uses a number of community-maintained Ansibles roles. Install them using the `ansible-galaxy` command:

```
$ ansible-galaxy install -r ansible/requirements.yml --force
```

Generate configuration files:
```bash
$ ./ansible/generate_config.sh
# follow the instructions
```

You can repeat the above step for every server that you want to setup.

Then create a file `inventories/custom/hosts` with the following content:
```ini
[webservers]
nickname
# ...
# add nicknames of more servers here
```

# Installation

Our setup is known to work for the following base images:

* `Ubuntu 20.04 (LTS) x64`

On the first deploy, the playbook must be run as the root user with:

```bash
ansible-playbook ansible/site.yml -i ansible/inventories/custom --ask-vault-pass --extra-vars "ansible_user=root"
```

Once the authorized SSH keys are in place, you can run deploy the latest with:

```bash
ansible-playbook ansible/site.yml -i ansible/inventories/custom --ask-vault-pass
```

## Backup and Restore

You can create a manual backup and download it by running:
```bash
ansible-playbook ansible/backup.yml -i ansible/inventories/production --ask-vault-pass
```

To restore the database (destructively!) into your local docker development setup:
```bash
ansible-playbook ansible/restore_locally.yml
```

## Troubleshooting

See our docs to debug issues with [Postmark](./Postmark.md).

## References

Disable password login for all users and disable root login:
* https://www.cyberciti.biz/faq/how-to-disable-ssh-password-login-on-linux/
* https://www.cyberciti.biz/tips/linux-unix-bsd-openssh-server-best-practices.html
* https://traefik.io/blog/traefik-2-0-docker-101-fc2893944b9d/
