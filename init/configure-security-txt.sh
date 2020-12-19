#!/bin/sh

# create publicly accessible security.txt file
curl -s https://raw.githubusercontent.com/ministryofjustice/security-guidance/main/contact/vulnerability-disclosure-security.txt -o /tmp/security.txt
mkdir /moj-app/public/.well-known
mv /tmp/security.txt /moj-app/public/.well-known/security.txt
