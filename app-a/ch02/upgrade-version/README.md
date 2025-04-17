# run it

```shell
sudo apt install -y vagrant

vagrant up
vagrant status
# vagrant destroy -y

vagrant ssh k8s-control-plane
k get nodes
```

# uprade control plane and workers

```shell
# makes it available under /vagrant directory
chmod +x upgrade.sh

vagrant ssh k8s-control-plane -c 'sudo /vagrant/upgrade.sh'

for i in {1..3}; do vagrant ssh worker-$i -c 'sudo /vagrant/upgrade.sh'; done
```

# backup and restore etc

## install 

https://github.com/etcd-io/etcd/releases/tag/v3.5.20
```shell
ETCD_VER=v3.5.16

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

/tmp/etcd-download-test/etcd --version
/tmp/etcd-download-test/etcdctl version
/tmp/etcd-download-test/etcdutl version
```

## restore etcd

- find paths to etcd certs 

```shell
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

   - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
```

perform backup

```shell
sudo ETCDCTL_API=3 ./etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt --key=/etc/kubernetes/pki/apiserver-etcd-client.key snapshot save /opt/etcd.bak

```
 
 - change state
 ```shell
 k run web02 --image nginx
 ```

- restore from the backup

```shell
sudo mkdir /opt/newetcd/
sudo ./etcdutl --data-dir /opt/newetcd/ snapshot restore /opt/etcd.bak
````

```shell
sudo systemctl stop kubelet
```

- kill static pods 
```shell
ps aux | grep -E "(kube-controller-manager|kube-apiserver|kube-scheduler|etcd)" | awk '{print $2}' | sudo xargs kill -9
```

sudo vim /etc/kubernetes/manifests/etcd.yaml
- replace usage `/var/lib/etcd/` in hostPath to ``

should be owned by root
```
sudo ls -la /var/lib/etcd/
```


```shell
sudo systemctl restart kubelet
k get nodes
```



