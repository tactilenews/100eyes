# Digital Ocean

We keep provider-specific documentation for [Digital Ocean](https://www.digitalocean.com/)
in this document.

## Managed Database

Digital Ocean offers managed databases for droplets. The benefits are e.g.
automated daily backups and point-in-time restores.

When you restore a database, Digital Ocean won't reset the current dabase but
will create a new database from the backup. In order to carry out the
restoration of a previous backup, the worfklow is as follows:

1. Restore a backup
2. Wait until the database is available
3. Change database host in your encrypted `host_vars` and point it to the new database
4. Re-deploy
