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

Now go to your server control panel and create and download a snapshot.
