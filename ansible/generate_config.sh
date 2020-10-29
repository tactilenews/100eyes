#!/usr/bin/env bash
set -e

echo "What's the nickname of your server?"
read nickname

echo "What will be the new domain?"
read domain

script_directory=$(dirname "$0")

traefik_domain="traefik.${domain}"
traefik_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
redaktion_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
sudo_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

postgres_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
secret_key_base=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
postgres_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
inbound_email_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
onboarding_token=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

CONFIG_FILE=$(mktemp /tmp/host.XXXXXXXXXX)


cat > $CONFIG_FILE <<- CONFIGURATION
netcup:
  nick: "${nickname}"  #
  root_password: # (optional) you can store your root password here
  sudo_password: "${sudo_password}"
  hostname: # (REQUIRED) e.g. v0000000000000000000.megasrv.de

dns:
  application_hostname: "${domain}" # e.g. 'hundred.tactile.news'
  traefik_hostname: "${traefik_domain}" # e.g. 'traefik.tactile.news'

traefik:
  acme_email_address: # (REQUIRED) an email address used for expiration warnings
  user: traefik
  password: "${traefik_password}"

rails:
  environment: production
  hundred_eyes_project_name: 100eyes
  onboarding_token: "${onboarding_token}"
  telegram_bot:
    api_key: # (REQUIRED) your telegram API token
    username: # (REQUIRED) your telegram bot name, e.g. 'HundredEyesBot'
  secret_key_base: "${secret_key_base}"
  postgres:
    user: app
    database: app_production
    password: "${postgres_password}"
  inbound_email_password: "${inbound_email_password}"
  sendgrid:
    username: apikey
    password: # (REQUIRED) sendgrid API key
    domain: "${domain}"
    from: "redaktion@${domain}"
  login:
    user: redaktion
    password: "${redaktion_password}"
CONFIGURATION

cat <<- INSTRUCTIONS
--------------------------------------------------------------------------------------------------------------------------
  INSTRUCTIONS:
--------------------------------------------------------------------------------------------------------------------------

  1. Configure your DNS-Server:

    A ${domain} -> IP ADDRESS
    A ${traefik_domain} -> IP ADDRESS

  2. Configure Sendgrid email delivery:

    Verify ${domain} as sender domain.

  3. Configure Sendgrid email inbound parse:

    https://actionmailbox:${inbound_email_password}@${domain}/rails/action_mailbox/sendgrid/inbound_emails

  4. Encrypt the configuration as host variable file:

    $ ansible-vault encrypt ${CONFIG_FILE} --output ${script_directory}/inventories/custom/host_vars/${nickname}.yml

  5. Add missing configuration, e.g. Telegram API token:

    $ ansible-vault edit ${script_directory}/inventories/custom/host_vars/${nickname}.yml

  6. Add your server "${nickname}" in your ${script_directory}/inventories/custom/hosts file:

    [webservers]
    ${nickname}
--------------------------------------------------------------------------------------------------------------------------
INSTRUCTIONS

