#!/bin/bash

# Step 1: install unzip, if not installed
if ! command -v unzip &> /dev/null; then
  echo "installing unzip"

  # update the apt package index
  sudo apt-get update -y

  # install packages
  sudo apt-get install -y unzip
fi

# Step 2: install aws, if not installed
if ! command -v aws &> /dev/null; then
  echo "installing aws"
  CPU_ARCH=$(uname -m)

  if [ ${CPU_ARCH} == 'aarch64' ]; then
    FILE="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
  elif [ ${CPU_ARCH} == 'x86_64' ]; then
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

# Step 3: CodeCommit passwordless access using IAM role
git config --global credential.helper '!aws codecommit credential-helper $@' 
git config --global credential.UseHttpPath true

# Step 4: Create directory
if [ ! -d "$HOME/codebase" ]; then
  mkdir -p $HOME/codebase
  cd $HOME/codebase
fi
