# rke2
The autoinst.xml creates account dave:password

Commands run after OpenSuse is installed:

```
curl -sfL https://get.rke2.io | sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
```
Add kubect to path
```
sudo vim ~/.bashrc
```
- Add the following line to the end of the file
```
export PATH=/var/lib/rancher/rke2/bin:$PATH"
```
- Copy the kubeconfig file to the user home for cluster access
```
sudo cp /etc/rancher/rke2/rke2.yaml ~/rke2.yaml
sudo chown dave:wheel ~/rke2.yaml
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