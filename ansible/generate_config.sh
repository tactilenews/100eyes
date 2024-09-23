#!/usr/bin/env bash
set -e

echo "What's the nickname of your server?"
read nickname

echo "What will be the new domain?"
read domain

script_directory=$(dirname "$0")

unameOut="$(uname -s)"

if [[ "$unameOut" == "Darwin" ]]; then #MacOS
  TR="gtr"
else
  TR="tr"
fi

domain_head="${domain%%.*}"
domain_tail="${domain#*.}"
traefik_domain="${domain_head}-traefik.${domain_tail}"
traefik_password=$(cat /dev/urandom | ${TR} -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
sudo_password=$(cat /dev/urandom | ${TR} -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)

secret_key_base=$(cat /dev/urandom | ${TR} -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
inbound_email_password=$(cat /dev/urandom | ${TR} -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

CONFIG_FILE=$(mktemp /tmp/host.XXXXXXXXXX)


cat > $CONFIG_FILE <<- CONFIGURATION
vps:
  nick: "${nickname}"  #
  root_password: # (optional) you can store your root password here
  sudo_password: "${sudo_password}"
  hostname: # (REQUIRED) e.g. the IP address of your origin web server

dns:
  application_hostname: "${domain}" # e.g. 'hundred.tactile.news'
  traefik_hostname: "${traefik_domain}" # e.g. 'traefik.tactile.news'

traefik:
  acme_email_address: # (REQUIRED) an email address used for expiration warnings
  user: traefik
  password: "${traefik_password}"
  cloudflare_dns_api_token: # (REQUIRED) a cloudflare API token with "edit" permissions on your zone

rails:
  environment: production
  hundred_eyes_project_name: 100eyes
  attr_encrypted_key: # (REQUIRED) To save encrypted attrs to db
  postmark:
    api_token: # (REQUIRED) API token for your new Postmark server
    transactional_stream: "outbound"
    broadcasts_stream: "broadcast"
  signal:
    server_phone_number:
    monitoring_url:
  secret_key_base: "${secret_key_base}"
  postgres:
    user: "${nickname}_app_user"
    db: "${nickname}_production"
    password: # (REQUIRED) copied from Digital Ocean database config
    host: # optional (e.g. for managed databases)
    port: # optional (e.g. for managed databases)
  inbound_email_password: "${inbound_email_password}"
  email_from_address: "redaktion@${domain}"
  sentry:
    dsn: # (REQUIRED) Sentry DSN to enable error tracking
  whats_app:
    server_phone_number: ""
  twilio:
    account_sid: ""
    auth_token: ""
    api_key:
      sid: ""
      secret: ""
  three_sixty_dialog:
    partner:
      id: ""
      username: ""
      password: ""

CONFIGURATION

cat <<- INSTRUCTIONS
--------------------------------------------------------------------------------------------------------------------------
  INSTRUCTIONS:
--------------------------------------------------------------------------------------------------------------------------

  1. Encrypt the configuration as host variable file:

    $ ansible-vault encrypt ${CONFIG_FILE} --output ${script_directory}/inventories/custom/host_vars/${nickname}.yml

  2. Add missing configuration, e.g. Telegram API token:

    $ ansible-vault edit ${script_directory}/inventories/custom/host_vars/${nickname}.yml

  3. Add your server "${nickname}" in your ${script_directory}/inventories/custom/hosts file:

    [webservers]
    ${nickname}

  4. Configure your DNS-Server:

    A  ${domain} -> IP ADDRESS
    A  ${traefik_domain} -> IP ADDRESS
    MX ${domain} -> inbound.postmarkapp.com

  5. Configure Postmark:

     - Log in to your Postmark account.

     - Add "${domain}" as sender domain in the "Sender Signatures"
       section. Follow the instructions displayed in the Postmark UI
       to verify the domain.

     - In the "Servers" section, create a new server. This allows you
       to keep separate email logs for every 100eyes instance.

     - Switch to the new  server and create a new message stream. Select
       "Broadcasts" as name *and* type of the new stream.

     - Switch to the "Settings" tab for the "Inbound" message stream.

     - Enter the following URL as the inbound webhook. Make sure to check the
       "Include raw email content" checkbox.
       https://actionmailbox:${inbound_email_password}@${domain}/rails/action_mailbox/postmark/inbound_emails

     - Add "${domain}" as the inbound domain.
--------------------------------------------------------------------------------------------------------------------------
INSTRUCTIONS
