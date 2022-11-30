#!/bin/bash

# Step 1: install package e.g. unzip, if not installed
if ! command -v unzip &> /dev/null; then
  echo "installing unzip"

  # update the apt package index
  sudo apt-get update -y

  # install packages
  sudo apt-get install -y unzip zip
fi

# Step 2: install aws, if not installed
if ! command -v aws &> /dev/null; then
  echo "installing aws"
  CPU_ARCH=$(uname -m)

  if [ ${CPU_ARCH} == "aarch64" ]; then
    FILE="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
  elif [ ${CPU_ARCH} == "x86_64" ]; then
    FILE="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  else
    echo "Unsupported CPU Architecture $CPU_ARCH"
    exit 1  
  fi

  # download file to /tmp
  cd /tmp
  curl "$FILE" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install

  # cleanup
  rm -rf aws
  rm awscliv2.zip
fi

# Step 3: CodeCommit passwordless access using IAM role or AWS CLI
GIT_URL=https://git-codecommit.us-east-2.amazonaws.com

git config --global \
credential."$GIT_URL".helper \
'!aws codecommit credential-helper $@'

git config --global \
credential."$GIT_URL".UseHttpPath true

# Step 4: Create directory
if [ -n "$CODESPACES" ]; then
  CODEBASE=/workspaces
elif [ -n "$GITPOD_WORKSPACE_ID" ]; then
  CODEBASE=/workspace
else
  CODEBASE=$HOME/codebase
  mkdir -p "$CODEBASE"
fi

# Step 5: Clone the repo
if [ -n "$CODEBASE" ] && [ -n "$REPO_UD" ]; then
  cd "$CODEBASE"
  export CODEBASE
  git clone $GIT_URL/v1/repos/$REPO_UD
fi
