#!/bin/bash

PROFILE=${PROFILE:-cdk}
DEFAULT_REGION=${DEFAULT_REGION:-eu-central-1}
DEBUG=${DEBUG:-true}
AWS_ENDPOINT=""
# disable aws pager
export AWS_PAGER=""

# When the ACCOUNT_ID is not passed as the actual ID but as a shell parameter reference,
# it will not be interpreted and resolved.
# This happens when using this orb in a circleci pipeline and orb-job parameters are
# to be set with values from env variables instead of hard-coded values in the pipl's config.yml.
# This is a circleci limitation.
# 
# The variable reference to the job's parameter will end-up here.
# That's why we evaluate it here to get the actual value of the parameter.
# The current implementation limits eval to resolve DEPLOYMENT_ACCOUNT_ID, only.
TryResolveAccountIdReference() {
  # if [[ ${ACCOUNT_ID} =~ ^\\$.* ]]; then # not supported for sh, only for bash or refactor to use grep
  if [ "${ACCOUNT_ID}" = "\$DEPLOYMENT_ACCOUNT_ID" ]; then
    ACCOUNT_ID=$(eval echo "${ACCOUNT_ID}")
  fi
}

AssumeRole() {
    if [ "${TEST_MODE}" = true ]; then
      echo "is test mode -> using localstack"
      AWS_ENDPOINT="--endpoint-url=http://localhost:4566"
    fi

    TryResolveAccountIdReference
    
    temp_role=$(aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" --role-session-name "role-session" ${AWS_ENDPOINT})
    key_id=$(echo "${temp_role}" | jq .Credentials.AccessKeyId | xargs)
    access_key=$(echo "${temp_role}" | jq .Credentials.SecretAccessKey | xargs)
    session_token=$(echo "${temp_role}" | jq .Credentials.SessionToken | xargs)
    aws configure set aws_access_key_id "${key_id}" --profile "${PROFILE}"
    aws configure set aws_secret_access_key "${access_key}" --profile "${PROFILE}"
    aws configure set aws_session_token "${session_token}" --profile "${PROFILE}"
    aws configure set region "${DEFAULT_REGION}" --profile "${PROFILE}"
    if [ "${DEBUG}" = true ]; then
      aws sts get-caller-identity --profile "${PROFILE}" ${AWS_ENDPOINT}
    fi
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
# shellcheck disable=SC2295
if [ "${0#*$ORB_TEST_ENV}" = "$0" ]; then
    AssumeRole
fi
