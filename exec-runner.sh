#!/bin/bash
echo "====start===="
# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# repo scopeのあるアクセストークン
# PAT classicの方を使う。Fine Grainedは対応されていない。
if [ -z "${GITHUB_ACCESS_TOKEN}" ]; then
  handle_error "GITHUB_ACCESS_TOKEN must be set"
fi

if [ -z "${GITHUB_API_DOMAIN}" ]; then
  handle_error "GITHUB_API_DOMAIN must be set"
fi

if [ -z "${GITHUB_DOMAIN}" ]; then
  handle_error "GITHUB_DOMAIN must be set"
fi

if [ -z "${GITHUB_REPOSITORY_NAME}" ]; then
  handle_error "GITHUB_REPOSITORY_NAME must be set"
fi

if [ -z "${GITHUB_REPOSITORY_OWNER}" ]; then
  handle_error "GITHUB_REPOSITORY_OWNER must be set"
fi

RESPONSE=$(curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_ACCESS_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://$GITHUB_API_DOMAIN/repos/$GITHUB_REPOSITORY_OWNER/$GITHUB_REPOSITORY_NAME/actions/runners/registration-token)


echo ${RESPONSE}

# # Check if the response contains an error
if echo "$RESPONSE" | jq .message | grep -q "Not Found"; then
    handle_error "Error: Repository not found or insufficient permissions."
fi

# # ランナー設定用トークンを取得する
GITHUB_RUNNER_REGISTRATION_TOKEN=$(echo "$RESPONSE" | jq -r .token)

# Verify if the token is not empty
if [ -z "$GITHUB_RUNNER_REGISTRATION_TOKEN" ]; then
    handle_error "Error: Failed to retrieve registration token."
fi

# Export the token
export GITHUB_RUNNER_REGISTRATION_TOKEN

export RUNNER_ALLOW_RUNASROOT=1
whoami
runnerName=$(hostname)

expect -c "
set timeout 10
log_user 0
spawn  ./config.sh --url https://${GITHUB_DOMAIN}/${GITHUB_REPOSITORY_OWNER}/${GITHUB_REPOSITORY_NAME} --token ${GITHUB_RUNNER_REGISTRATION_TOKEN}
expect  -re \"Enter the name of the runner group to add this runner to:.*\"
send \"\n\"
expect  -re \"Enter the name of runner:.*\"
send \"${runnerName}\n\"
expect  -re \"Enter any additional labels.*\"
send \"\n\"
expect  -re \"Enter name of work folder:.*\"
send \"\n\"
expect \"#\"
exit 0
"

./run.sh
