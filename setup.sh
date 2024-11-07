#!/bin/sh
NC='\033[0m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
os_name=$(grep 'PRETTY_NAME' /etc/os-release | awk -F '=' '{gsub(/"/, "", $2); print $2}')

printf "${CYAN}Please provides some system variables${NC}\n"
read -p "Enter the hostname: " HOSTNAME
read -p "Enter the host IP address: " HOSTIP

printf "${GREEN}Updating packages${NC}\n"
sudo zypper refresh && sudo zypper update -y

printf "${GREEN}Updating hosts file${NC}\n"
echo "$HOSTIP $HOSTNAME" | sudo tee -a /etc/hosts

printf "${GREEN}Updating packages${NC}\n"
sudo zypper refresh && sudo zypper update -y

printf "${GREEN}Cloning RKE2 repositorys${NC}\n"
git clone https://github.com/deemack/homelab.git

printf "${GREEN}System is ready to be provisioned via Ansible${NC}\n"
cd rke2

printf "${GREEN}Eg. ansible-playbook -i inventory playbooks/site.yaml -K --limit kubedev${NC}\n"
