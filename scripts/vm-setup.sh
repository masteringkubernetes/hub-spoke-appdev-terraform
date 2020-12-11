#!/bin/bash

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get install -y apt-transport-https gnupg2
sudo apt-get install -y kubectl
sudo apt-get install terraform
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
