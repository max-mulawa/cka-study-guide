#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

if [ -z ${K8S_VERSION+x} ]; then
  K8S_VERSION=1.31.1-1.1
fi

# Install containerd container runtime
sudo apt install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install containerd.io
sudo systemctl start containerd
sudo systemctl enable containerd
sudo systemctl status containerd
sudo mv etc/containerd/config.toml etc/containerd/config.toml.orig
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo sed -i "s/pause:3.8/pause:3.10/g" "/etc/containerd/config.toml"
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz
sudo systemctl restart containerd

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl socat
sudo curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION:0:4}/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION:0:4}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes binaries
sudo apt-get update
sudo apt-get install -y \
  kubeadm=$K8S_VERSION \
  kubelet=$K8S_VERSION \
  kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl

# Required for kubeadm preinstall checks
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl net.ipv4.ip_forward=1

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set alias for kubectl command
echo "alias k=kubectl" >> /home/vagrant/.bashrc