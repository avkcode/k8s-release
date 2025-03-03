# Define systemd unit files for each Kubernetes component

define systemdEtcd
[Unit]
Description=etcd - highly-available key-value store
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
User=etcd
Group=etcd
Type=notify
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/local/bin/etcd

# Performance and resource tuning
LimitNOFILE=65536
LimitMEMLOCK=infinity
TimeoutStartSec=0
Restart=on-failure
RestartSec=5s

# High load optimizations
CPUShares=1024
MemoryLimit=4G
IOWeight=100

# Throttling and rate limiting
StartLimitInterval=60s
StartLimitBurst=10

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=etcd

# Security
ProtectSystem=full
ProtectHome=true
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
endef
export systemdEtcd

define etcdConf
# Node and cluster configuration
ETCD_NAME="node1"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://<node-ip>:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://<node-ip>:2379"
ETCD_INITIAL_CLUSTER="node1=http://<node-ip>:2380,node2=http://<node2-ip>:2380,node3=http://<node3-ip>:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-1"
ETCD_INITIAL_CLUSTER_STATE="new"

# Performance tuning for high load
ETCD_HEARTBEAT_INTERVAL="100"  # Default: 100ms, reduce for faster leader election
ETCD_ELECTION_TIMEOUT="500"    # Default: 1000ms, reduce for faster failover
ETCD_SNAPSHOT_COUNT="10000"    # Default: 100000, reduce to lower snapshot frequency
ETCD_MAX_REQUEST_BYTES="1572864"  # Default: 1.5MB, increase for larger requests
ETCD_QUOTA_BACKEND_BYTES="8589934592"  # Default: 2GB, increase for larger datasets

# Resource limits
ETCD_MAX_TXN_OPS="1024"        # Default: 128, increase for more operations per transaction
ETCD_MAX_CONCURRENT_STREAMS="1024"  # Default: 32, increase for more concurrent streams

# Network and I/O tuning
ETCD_SOCKET_REUSE_ADDRESS="true"  # Reuse sockets to reduce overhead
ETCD_CLIENT_CERT_AUTH="true"    # Enable client certificate authentication
ETCD_PEER_CLIENT_CERT_AUTH="true"  # Enable peer client certificate authentication

# Logging and debugging
ETCD_DEBUG="false"              # Disable debug logging for performance
ETCD_LOG_LEVEL="info"           # Set log level to info or higher
ETCD_LOG_OUTPUT="stdout"        # Output logs to stdout for systemd/journald capture

# Security
ETCD_CLIENT_CERT_FILE="/etc/etcd/ssl/client.crt"
ETCD_CLIENT_KEY_FILE="/etc/etcd/ssl/client.key"
ETCD_TRUSTED_CA_FILE="/etc/etcd/ssl/ca.crt"
ETCD_PEER_CERT_FILE="/etc/etcd/ssl/peer.crt"
ETCD_PEER_KEY_FILE="/etc/etcd/ssl/peer.key"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/ssl/ca.crt"

# Auto-compaction and defragmentation
ETCD_AUTO_COMPACTION_RETENTION="1"  # Compact every 1 hour (e.g., "1h")
ETCD_AUTO_COMPACTION_MODE="periodic"  # Periodic compaction to reduce fragmentation
endef
export etcdConf

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
all: etcd.service etcd.conf kube-apiserver.service kube-controller-manager.service kube-scheduler.service kubelet.service kube-proxy.service

etcd.service:
	@echo "$${systemdEtcd}" > $@

etcd.conf:
	@echo "$${etcdConf}" > $@

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
	@rm -f *.service *.conf
