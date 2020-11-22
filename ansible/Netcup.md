# Netcup

We keep provider-specific documentation for [Netcup](https://www.netcup.de/) in
this document.

## Snapshot

As of winter 2020, you cannot upload your SSH public key for the initial user
when you create or rebuild a new VPS through the server control panel.

One idea to make the setup easier is to create a snapshot of a base image with
a user `ansible` and all authorized keys of your friends in place. You could
rebuild a new VPS based on the snapshot.


Add public keys of your friends in folder `./ansible/ssh/`. It should look like
this:
```
$ ls .ansible/ssh
jakob_id_rsa.pub  till.pub
```

Run this playbook to create the ansible user with authorized keys in place and
ensure basic security:
```
$ ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ansible/only_initial_setup.yml -i ansible/inventories/custom --ask-pass --ask-vault-pass
```

You need `sshpass` installed and you will be asked for:
```
SSH password: # root user password
Vault password: # vault password
```

Now go to your server control panel and create and download a snapshot.
