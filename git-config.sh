#!/bin/bash

# CodeCommit passwordless access using IAM role
git config --global credential.helper '!aws codecommit credential-helper $@' 
git config --global credential.UseHttpPath true
