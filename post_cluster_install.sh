#!/bin/bash


echo 'export PATH=/var/lib/rancher/rke2/bin:$PATH' | sudo tee -a ~/.bashrc
source ~/.bashrc
sudo cp /etc/rancher/rke2/rke2.yaml ~/rke2.yaml
sudo chown k8sadmin:wheel ~/rke2.yaml