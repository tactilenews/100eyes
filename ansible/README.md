# Local setup

Our setup uses a number of community-maintained Ansibles roles. Install them using the `ansible-galaxy` command:

```
ansible-galaxy collection install community.general
ansible-galaxy install geerlingguy.docker
ansible-galaxy install geerlingguy.pip
ansible-galaxy install dev-sec.os-hardening
ansible-galaxy install dev-sec.ssh-hardening
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

If your authorized SSH keys are in place you can run the entire installation of
the application with:

```bash
ansible-playbook ansible/site.yml -i ansible/inventories/custom --ask-vault-pass
```

If you haven't setup the authorized SSH keys, set username to `root` on the
first run:
```bash
ansible-playbook ansible/site.yml -i ansible/inventories/custom --ask-vault-pass --extra-vars "ansible_user=root"
```

## Provider specific instructions

See [Netcup](./Netcup.md).

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
