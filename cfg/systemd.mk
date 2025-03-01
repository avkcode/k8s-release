# Define systemd unit files for each Kubernetes component

define systemdEtcd
[Unit]
Description=etcd - Distributed Key-Value Store
Documentation=https://etcd.io/docs/
After=network.target

[Service]
ExecStart=/usr/local/bin/etcd \
  --data-dir=/var/lib/etcd \
  --listen-client-urls=http://127.0.0.1:2379 \
  --advertise-client-urls=http://127.0.0.1:2379
Restart=always
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
endef
export systemdEtcd

define systemdKubeApiserver
[Unit]
Description=Kubernetes API Server
Documentation=https://kubernetes.io/docs/concepts/overview/components/#kube-apiserver
After=network.target etcd.service

[Service]
ExecStart=/usr/local/bin/kube-apiserver \
  --etcd-servers=http://127.0.0.1:2379 \
  --allow-privileged=true \
  --service-cluster-ip-range=10.96.0.0/12 \
  --secure-port=6443 \
  --advertise-address=0.0.0.0 \
  --client-ca-file=/etc/kubernetes/pki/ca.crt \
  --tls-cert-file=/etc/kubernetes/pki/apiserver.crt \
  --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
Restart=always
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
endef
export systemdKubeApiserver

define systemdKubeControllerManager
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://kubernetes.io/docs/concepts/overview/components/#kube-controller-manager
After=network.target kube-apiserver.service

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \
  --kubeconfig=/etc/kubernetes/controller-manager.conf \
  --allocate-node-cidrs=true \
  --cluster-cidr=10.244.0.0/16 \
  --service-cluster-ip-range=10.96.0.0/12
Restart=always
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
endef
export systemdKubeControllerManager

define systemdKubeScheduler
[Unit]
Description=Kubernetes Scheduler
Documentation=https://kubernetes.io/docs/concepts/overview/components/#kube-scheduler
After=network.target kube-apiserver.service

[Service]
ExecStart=/usr/local/bin/kube-scheduler \
  --kubeconfig=/etc/kubernetes/scheduler.conf
Restart=always
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
endef
export systemdKubeScheduler

define systemdKubelet
[Unit]
Description=Kubernetes Kubelet
Documentation=https://kubernetes.io/docs/concepts/overview/components/#kubelet
After=network.target

[Service]
ExecStart=/usr/local/bin/kubelet \
  --config=/var/lib/kubelet/config.yaml \
  --kubeconfig=/etc/kubernetes/kubelet.conf \
  --container-runtime=remote \
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock
Restart=always
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
endef
export systemdKubelet

define systemdKubeProxy
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://kubernetes.io/docs/concepts/overview/components/#kube-proxy
After=network.target kube-apiserver.service

[Service]
ExecStart=/usr/local/bin/kube-proxy \
  --config=/var/lib/kube-proxy/config.conf
Restart=always
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
endef
export systemdKubeProxy

# Targets to generate systemd unit files
all: etcd.service kube-apiserver.service kube-controller-manager.service kube-scheduler.service kubelet.service kube-proxy.service

etcd.service:
	@echo "$${systemdEtcd}" > $@

kube-apiserver.service:
	@echo "$${systemdKubeApiserver}" > $@

kube-controller-manager.service:
	@echo "$${systemdKubeControllerManager}" > $@

kube-scheduler.service:
	@echo "$${systemdKubeScheduler}" > $@

kubelet.service:
	@echo "$${systemdKubelet}" > $@

kube-proxy.service:
	@echo "$${systemdKubeProxy}" > $@

clean:
	@rm -f *.service
