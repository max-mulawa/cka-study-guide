export NODE=$(hostname -s)
echo $NODE

sudo sed -i 's/31/32/g' /etc/apt/sources.list.d/kubernetes.list

sudo apt update

sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm='1.32.3-1.1' && \
sudo apt-mark hold kubeadm

kubeadm version

if [[ $NODE = "k8s-control-plane" ]]
then
    sudo kubeadm upgrade apply --yes v1.32.3 
else
    sudo kubeadm upgrade node
fi

kubectl drain $NODE --ignore-daemonsets

sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y kubelet='1.32.3-1.1' kubectl='1.32.3-1.1' && \
sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet

kubectl uncordon $NODE
kubectl get nodes