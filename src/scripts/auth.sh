#!/usr/bin/env bash

# echo "Establishing the OIDC session with account...${DEPLOYMENT_ACCOUNT_ID}..and the Role ${OIDC_ROLE}"
# temp_role=$(aws sts assume-role-with-web-identity --role-arn "arn:aws:iam::${DEPLOYMENT_ACCOUNT_ID}:role/${OIDC_ROLE}" --role-session-name "web-identity-role-session" --web-identity-token "${CIRCLE_OIDC_TOKEN}")
# key_id=$(echo "${temp_role}" | jq .Credentials.AccessKeyId | xargs)
# access_key=$(echo "${temp_role}" | jq .Credentials.SecretAccessKey | xargs)
# session_token=$(echo "${temp_role}" | jq .Credentials.SessionToken | xargs)
# echo "export AWS_ACCESS_KEY_ID=${key_id}" >> $BASH_ENV
# echo "export AWS_SECRET_ACCESS_KEY=${access_key}" >> $BASH_ENV
# echo "export AWS_SESSION_TOKEN=${session_token}" >> $BASH_ENV
# source $BASH_ENV
# echo "OIDC session established"

set_aws_profile() {
  local key_id="$1"
  local access_key="$2"
  local session_token="$3"
  local mode="$4"

  echo "Establishing the ${mode} session with account..."
  echo "export AWS_ACCESS_KEY_ID=${key_id}" >> "$BASH_ENV"
  echo "export AWS_SECRET_ACCESS_KEY=${access_key}" >> "$BASH_ENV"
  echo "export AWS_SESSION_TOKEN=${session_token}" >> "$BASH_ENV"
  source "$BASH_ENV"
  echo "OIDC session established"
}


generate_temp_token() {
  local mode="$1"
  local account_id="$2"
  local role_name="$3"
  local token_or_profile="$4"

  local temp_role

  if [ "$mode" == "oidc" ]; then
    temp_role=$(aws sts assume-role-with-web-identity \
      --role-arn "arn:aws:iam::${account_id}:role/${role_name}" \
      --role-session-name "web-identity-role-session" \
      --web-identity-token "${CIRCLE_OIDC_TOKEN}")
  elif [ "$mode" == "static" ]; then
    temp_role=$(aws sts assume-role \
      --role-arn "arn:aws:iam::${account_id}:role/${role_name}" \
      --role-session-name "static-role-session" \
      --profile "${token_or_profile}")
  else
    echo "Invalid mode: $mode. Use 'oidc' or 'static'."
    exit 1
  fi

  local key_id
  key_id=$(echo "${temp_role}" | jq -r .Credentials.AccessKeyId)
  local access_key
  access_key=$(echo "${temp_role}" | jq -r .Credentials.SecretAccessKey)
  local session_token
  session_token=$(echo "${temp_role}" | jq -r .Credentials.SessionToken)

  echo "${key_id} ${access_key} ${session_token}"
}




main() {
    if [ "$#" -ne 4 ]; then
        echo "Usage:"
        echo "  For OIDC Mode : $0 oidc <account_id> <role_name> <oidc_token>"
        echo "  For static credentials: $0 static <account_id> <role_name> <profile>"
        exit 1
    fi

    local mode="$1"
    local account_id="$2"
    local role_name="$3"
    local profile="$4"

    read key_id access_key session_token < <(generate_temp_token "$mode" "$account_id" "$role_name" "$token_or_profile")
    set_aws_profile "$key_id" "$access_key" "$session_token" "$mode"
}






main "#@"