#!/usr/bin/env bash

echo "Establishing the OIDC session with account...${DEPLOYMENT_ACCOUNT_ID}..and the Role ${OIDC_ROLE}"
temp_role=$(aws sts assume-role-with-web-identity --role-arn "arn:aws:iam::${DEPLOYMENT_ACCOUNT_ID}:role/${OIDC_ROLE}" --role-session-name "web-identity-role-session" --web-identity-token "${CIRCLE_OIDC_TOKEN}")
key_id=$(echo "${temp_role}" | jq .Credentials.AccessKeyId | xargs)
access_key=$(echo "${temp_role}" | jq .Credentials.SecretAccessKey | xargs)
session_token=$(echo "${temp_role}" | jq .Credentials.SessionToken | xargs)
echo "export AWS_ACCESS_KEY_ID=${key_id}" >> $BASH_ENV
echo "export AWS_SECRET_ACCESS_KEY=${access_key}" >> $BASH_ENV
echo "export AWS_SESSION_TOKEN=${session_token}" >> $BASH_ENV
source $BASH_ENV
echo "OIDC session established"