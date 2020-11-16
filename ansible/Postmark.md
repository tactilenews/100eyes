# Postmark

We cover instructions for manual debugging of our Postmark email delivery service here.

## Resend failed inbound emails

Make sure you have [jq](https://stedolan.github.io/jq/) installed.

Go to postmark web UI:
  1. Click on your Server
  2. Choose Inbound
  3. Click on Activity Tab

Filter for "Failed" emails.

On each email, click on the subject and then scroll down and click on "Raw source". Save the content to a file "rawMail". Then run the following:

```console
cat rawEmail | jq -aRs . > rawEmailString
```

Go to the "JSON" tab on the email in the Postmark UI.

Grab the content there and add a key "RawEmail" with the String-escaped content of file "rawEmailString".

Open Postman and send a POST request to your `<WEBHOOK_URL>` with the content mentioned above as request body.

Your E-Mail should be visible now in your 100eyes UI.
