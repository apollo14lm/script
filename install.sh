#!/bin/bash

# Exit script if command fails
set -e

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

  if [ -n "$CLOUD_SHELL" ]; then
    mkdir -p $HOME/app
    mkdir -p $HOME/bin
    sudo ./aws/install -i $HOME/app/aws-cli -b $HOME/bin

    PATH="$HOME/bin:$PATH"
    export PATH
  else
    sudo ./aws/install
  fi  
  
  # cleanup
  rm -rf aws
  rm awscliv2.zip
fi

# Step 3: CodeCommit passwordless access using IAM role or AWS CLI
GIT_URL=https://git-codecommit.us-east-2.amazonaws.com

# backup file
if [ -f "$HOME/.gitconfig" ] && [ ! -f "$HOME/.gitconfig_bak" ]; then
  cp $HOME/.gitconfig $HOME/.gitconfig_bak
fi

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
elif [ -d "/projects" ]; then
  CODEBASE=/projects  
else
  CODEBASE=$HOME/codebase
  mkdir -p "$CODEBASE"
fi

export CODEBASE

# Step 5: Clone the repo
if [ -n "$CODEBASE" ] && [ -n "$REPO_UD" ] && [ ! -d "$CODEBASE/$REPO_UD" ]; then
  cd "$CODEBASE"
  git clone $GIT_URL/v1/repos/$REPO_UD
fi

# Step 6: Create .vscode link
if [ ! -L "$CODEBASE/.vscode" ] && [ ! -d "$CODEBASE/.vscode" ]; then
  ln -s $CODEBASE/$REPO_UD/.vscode $CODEBASE/.vscode

  cp -n $CODEBASE/.vscode/settings-template.json $CODEBASE/.vscode/settings.json
  cp -n $CODEBASE/.vscode/extensions-template.json $CODEBASE/.vscode/extensions.json
fi  

# Step 7: Install dotfile
cd $CODEBASE/$REPO_UD/script
source ./dotfile.sh install
