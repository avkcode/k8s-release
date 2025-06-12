#!/bin/bash
set -e

# Create output directories
mkdir -p /certs /output

# Create CA
echo "Generating CA certificates..."
openssl genrsa -out /certs/ca.key 4096
openssl req -x509 -new -sha512 -nodes \
  -key /certs/ca.key -days 3653 \
  -config /ca.conf \
  -out /certs/ca.crt

# Create certificates for each component
certs=(
  "admin" "node-0" "node-1"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)

for i in ${certs[*]}; do
  echo "Generating certificates for ${i}..."
  openssl genrsa -out "/certs/${i}.key" 4096

  # Create a temporary config file for this specific component with a more complete structure
  cat > "/tmp/${i}.conf" << EOF
[ req ]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[ dn ]
C = US
ST = California
L = San Francisco
O = Kubernetes
OU = K8s release
CN = ${i}

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

  # Add the appropriate extensions section from ca.conf
  if grep -q "\[ ${i} \]" /ca.conf; then
    # Extract the section and any referenced sections
    sed -n "/\[ ${i} \]/,/\[/p" /ca.conf | sed '$d' >> "/tmp/${i}.conf"
    
    # If this component references another section (like alt_names), extract that too
    if grep -q "subjectAltName = @alt_names_${i}" "/tmp/${i}.conf"; then
      sed -n "/\[ alt_names_${i} \]/,/\[/p" /ca.conf | sed '$d' >> "/tmp/${i}.conf"
    elif grep -q "subjectAltName = @alt_names" "/tmp/${i}.conf"; then
      sed -n "/\[ alt_names \]/,/\[/p" /ca.conf | sed '$d' >> "/tmp/${i}.conf"
    fi
  else
    # Use default extensions if no specific section exists
    cat >> "/tmp/${i}.conf" << EOF
[ alt_names ]
DNS.1 = kubernetes
DNS.2 = ${i}
EOF
  fi

  # Generate CSR using the temporary config
  openssl req -new -key "/certs/${i}.key" -sha256 \
    -config "/tmp/${i}.conf" \
    -out "/certs/${i}.csr"

  # Sign the certificate
  openssl x509 -req -days 3653 -in "/certs/${i}.csr" \
    -sha256 -CA "/certs/ca.crt" \
    -CAkey "/certs/ca.key" \
    -CAcreateserial \
    -out "/certs/${i}.crt"
    
  # Clean up the temporary config
  rm "/tmp/${i}.conf"
done

# Set version for packages
VERSION=${CERT_VERSION:-"1.0.0"}
PACKAGE_TYPE=${PACKAGE_TYPE:-"deb"}

# Create package directories
echo "Creating package directories..."

# CA certificates package
PKG_DIR_CA="/tmp/kubernetes-ca-certs_${VERSION}"
mkdir -p ${PKG_DIR_CA}/etc/kubernetes/pki
cp /certs/ca.crt ${PKG_DIR_CA}/etc/kubernetes/pki/
cp /certs/ca.key ${PKG_DIR_CA}/etc/kubernetes/pki/
chmod 600 ${PKG_DIR_CA}/etc/kubernetes/pki/ca.key

# API Server certificates package
PKG_DIR_API="/tmp/kubernetes-apiserver-certs_${VERSION}"
mkdir -p ${PKG_DIR_API}/etc/kubernetes/pki
cp /certs/kube-api-server.crt ${PKG_DIR_API}/etc/kubernetes/pki/apiserver.crt
cp /certs/kube-api-server.key ${PKG_DIR_API}/etc/kubernetes/pki/apiserver.key
chmod 600 ${PKG_DIR_API}/etc/kubernetes/pki/apiserver.key

# Controller Manager certificates package
PKG_DIR_CM="/tmp/kubernetes-controller-manager-certs_${VERSION}"
mkdir -p ${PKG_DIR_CM}/etc/kubernetes/pki
cp /certs/kube-controller-manager.crt ${PKG_DIR_CM}/etc/kubernetes/pki/controller-manager.crt
cp /certs/kube-controller-manager.key ${PKG_DIR_CM}/etc/kubernetes/pki/controller-manager.key
chmod 600 ${PKG_DIR_CM}/etc/kubernetes/pki/controller-manager.key

# Scheduler certificates package
PKG_DIR_SCHED="/tmp/kubernetes-scheduler-certs_${VERSION}"
mkdir -p ${PKG_DIR_SCHED}/etc/kubernetes/pki
cp /certs/kube-scheduler.crt ${PKG_DIR_SCHED}/etc/kubernetes/pki/scheduler.crt
cp /certs/kube-scheduler.key ${PKG_DIR_SCHED}/etc/kubernetes/pki/scheduler.key
chmod 600 ${PKG_DIR_SCHED}/etc/kubernetes/pki/scheduler.key

# Proxy certificates package
PKG_DIR_PROXY="/tmp/kubernetes-proxy-certs_${VERSION}"
mkdir -p ${PKG_DIR_PROXY}/etc/kubernetes/pki
cp /certs/kube-proxy.crt ${PKG_DIR_PROXY}/etc/kubernetes/pki/kube-proxy.crt
cp /certs/kube-proxy.key ${PKG_DIR_PROXY}/etc/kubernetes/pki/kube-proxy.key
chmod 600 ${PKG_DIR_PROXY}/etc/kubernetes/pki/kube-proxy.key

# Service Account certificates package
PKG_DIR_SA="/tmp/kubernetes-service-account-certs_${VERSION}"
mkdir -p ${PKG_DIR_SA}/etc/kubernetes/pki
cp /certs/service-accounts.crt ${PKG_DIR_SA}/etc/kubernetes/pki/sa.crt
cp /certs/service-accounts.key ${PKG_DIR_SA}/etc/kubernetes/pki/sa.key
chmod 600 ${PKG_DIR_SA}/etc/kubernetes/pki/sa.key

# Node certificates packages
for node in "node-0" "node-1"; do
  PKG_DIR_NODE="/tmp/kubernetes-${node}-certs_${VERSION}"
  mkdir -p ${PKG_DIR_NODE}/var/lib/kubelet
  cp /certs/${node}.crt ${PKG_DIR_NODE}/var/lib/kubelet/kubelet.crt
  cp /certs/${node}.key ${PKG_DIR_NODE}/var/lib/kubelet/kubelet.key
  cp /certs/ca.crt ${PKG_DIR_NODE}/var/lib/kubelet/ca.crt
  chmod 600 ${PKG_DIR_NODE}/var/lib/kubelet/kubelet.key
done

# Create DEBIAN directories and control files for each package
for pkg in "kubernetes-ca-certs" "kubernetes-apiserver-certs" "kubernetes-controller-manager-certs" \
           "kubernetes-scheduler-certs" "kubernetes-proxy-certs" "kubernetes-service-account-certs" \
           "kubernetes-node-0-certs" "kubernetes-node-1-certs"; do
  
  PKG_DIR="/tmp/${pkg}_${VERSION}"
  mkdir -p ${PKG_DIR}/DEBIAN
  
  # Create control file
  cat > ${PKG_DIR}/DEBIAN/control << EOF
Package: ${pkg}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Kubernetes Packager <maintainer@example.com>
Description: Kubernetes TLS certificates for ${pkg}
EOF

  # Create postinst script to set permissions
  cat > ${PKG_DIR}/DEBIAN/postinst << EOF
#!/bin/bash
echo "${pkg} certificates have been installed."
# Set proper permissions for private keys
find /etc/kubernetes/pki -name "*.key" -exec chmod 600 {} \; 2>/dev/null || true
find /var/lib/kubelet -name "*.key" -exec chmod 600 {} \; 2>/dev/null || true
EOF
  chmod 755 ${PKG_DIR}/DEBIAN/postinst
done

# Build the packages
echo "Building packages..."
for pkg in "kubernetes-ca-certs" "kubernetes-apiserver-certs" "kubernetes-controller-manager-certs" \
           "kubernetes-scheduler-certs" "kubernetes-proxy-certs" "kubernetes-service-account-certs" \
           "kubernetes-node-0-certs" "kubernetes-node-1-certs"; do
  
  PKG_DIR="/tmp/${pkg}_${VERSION}"
  
  if [ "$PACKAGE_TYPE" = "deb" ] || [ "$PACKAGE_TYPE" = "all" ]; then
    # Create the Debian package
    echo "Building Debian package for ${pkg}..."
    dpkg-deb --build ${PKG_DIR}
    mv ${PKG_DIR}.deb /output/${pkg}_${VERSION}_amd64.deb
    echo "Debian package created: /output/${pkg}_${VERSION}_amd64.deb"
  fi
  
  if [ "$PACKAGE_TYPE" = "rpm" ] || [ "$PACKAGE_TYPE" = "all" ]; then
    # For RPM packages, we would need to implement similar logic as in package-builder.sh
    # This is a simplified version
    echo "RPM packaging for certificates not implemented yet"
  fi
done

# Ensure the output directory is accessible
chmod -R 777 /output

echo "Certificate packages created:"
ls -la /output/
