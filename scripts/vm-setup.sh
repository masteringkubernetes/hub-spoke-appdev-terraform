#!/bin/bash

sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash