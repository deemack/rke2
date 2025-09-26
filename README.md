# rke2
### Bootable USB Creation
* Download the OpenSUSE Offline Server ISO (~4.3GB) https://get.opensuse.org/leap/15.6/?type=server#download
* Use RUFUS to create a Bootable USB
* Copy the autoinst.xml to the root of the Bootable USB
  * Note the autoinst.xml creates a bootstrap admin account k8sadmin:password

### Server OS installation
* USB Boot Install OpenSUSE to the miniPC
  * The NVME Primary Drive will automatically be partitioned and used for the OS installation

### Commands run after OpenSuse is installed:
Change hostname
```
sudo hostnamectl set-hostname [kubeprod/kubedev/etc]
```
Clone this repo
```
git clone https://github.com/deemack/rke2.git
```
Change to the rke2 directory
```
cd rke2
```
Make the initialise.sh script executable
```
sudo chmod +x initialise.sh
```
Run the initialise script to set the hostname and deploy rke2
```
sh initialise.sh
```
Run the playbook to deploy metal LB
```
ansible-playbook -i production site.yml --tags deploy_metallb --limit kubeprod -K --ask-vault-pass
```
Run the playbook to deploy the rest of the site
```
ansible-playbook -i production deploy_apps.yml --limit kubeprod -K --ask-vault-pass
```
Add kubect to path
```
sudo vim ~/.bashrc
```
- Add the following line to the end of the file
```
export PATH=/var/lib/rancher/rke2/bin:$PATH"
```
Copy the kubeconfig file to the user home for cluster access
```
sudo cp /etc/rancher/rke2/rke2.yaml ~/rke2.yaml
sudo chown k8sadmin:wheel ~/rke2.yaml
```

After running this installation:

- The rke2-server service will be installed. The rke2-server service will be configured to automatically restart after node reboots or if the process crashes or is killed.
- Additional utilities will be installed at /var/lib/rancher/rke2/bin/. They include: kubectl, crictl, and ctr. Note that these are not on your path by default.
- Two cleanup scripts, rke2-killall.sh and rke2-uninstall.sh, will be installed to the path at:
/usr/local/bin for regular file systems
/opt/rke2/bin for read-only and brtfs file systems
INSTALL_RKE2_TAR_PREFIX/bin if INSTALL_RKE2_TAR_PREFIX is set
- A kubeconfig file will be written to /etc/rancher/rke2/rke2.yaml.
- A token that can be used to register other server or agent nodes will be created at /var/lib/rancher/rke2/server/node-token

# delete a namespace and all its resources when it is stuck on Terminating
```
NS=`kubectl get ns |grep Terminating | awk 'NR==1 {print $1}'` && kubectl get namespace "$NS" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
```

or

Need to remove the finalizer for kubernetes.

Step 1:
```
kubectl get namespace <YOUR_NAMESPACE> -o json > <YOUR_NAMESPACE>.json
```
remove kubernetes from finalizers array which is under spec
Step 2:
```
kubectl replace --raw "/api/v1/namespaces/<YOUR_NAMESPACE>/finalize" -f ./<YOUR_NAMESPACE>.json
```
Step 3:
```
kubectl get namespace
```
You can see that the annoying namespace is gone.
