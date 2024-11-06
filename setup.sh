#!/bin/sh
NC='\033[0m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
os_name=$(grep 'PRETTY_NAME' /etc/os-release | awk -F '=' '{gsub(/"/, "", $2); print $2}')


printf "${CYAN}Please provides some system variables${NC}\n"
read -p "Enter the hostname: " HOSTNAME
read -p "Enter the host IP address: " HOSTIP

printf "${GREEN}Updating hosts file${NC}\n"
echo "$HOSTIP $HOSTNAME" | sudo tee -a /etc/hosts

printf "${GREEN}Add entry to fstab for SSD${NC}\n"
uuid=$(lsblk -no uuid /dev/sda | xargs)
fstab_entry="UUID=""$uuid"" /mnt/storage ntfs permissions,locale=en_US.utf8 0 2"
echo $fstab_entry | sudo tee -a /etc/fstab
sudo mount -a

printf "${GREEN}Updating packages${NC}\n"
sudo zypper refresh && sudo zypper update -y