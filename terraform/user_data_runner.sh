#!/bin/bash
set -e

# 1. Update and Install Dependencies
yum update -y
yum install -y docker git libicu jq

# 2. Configure Docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
chmod 666 /var/run/docker.sock

# 3. Create Runner Directory
mkdir /actions-runner && cd /actions-runner

# 4. Fetch the GitHub Token from AWS Secrets Manager
# We use the standard region us-east-1
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id github-runner-token --region us-east-1 --query SecretString --output text)
GITHUB_PAT=$(echo $SECRET_JSON | jq -r .token)

# 5. Get Registration Token dynamically from GitHub API
# We use the repo_url passed from Terraform
REPO_URL="${repo_url}"
# Extract owner/repo from URL (e.g., TalGold01/kubernetes-project)
REPO_PATH=$(echo "$REPO_URL" | sed 's/https:\/\/github.com\///')

REG_TOKEN=$(curl -s -X POST -H "Authorization: token $GITHUB_PAT" -H "Accept: application/vnd.github+json" https://api.github.com/repos/$REPO_PATH/actions/runners/registration-token | jq -r .token)

# 6. Download GitHub Actions Runner
RUNNER_VERSION="${runner_version}"

echo "Downloading Runner Version: $RUNNER_VERSION"
curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

# 7. Configure and Start
# Name the runner based on the hostname to ensure uniqueness
runuser -l ec2-user -c "/actions-runner/config.sh --url $REPO_URL --token $REG_TOKEN --name aws-ec2-runner-$(hostname) --labels self-hosted,ec2 --unattended"

# Install as a service
./svc.sh install ec2-user
./svc.sh start