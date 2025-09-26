#!/bin/bash

read -p "Enter the hostname for this RKE2 server: " hostname
sudo hostnamectl set-hostname $hostname

ansible-playbook deploy_rke2.yml --limit $hostname -K --ask-vault-pass
