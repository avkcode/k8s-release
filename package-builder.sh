#!/bin/bash
set -e

# This script creates a Debian package from a binary
# Usage: ./package-builder.sh <binary_name> <version> <description>

BINARY_NAME=$1
VERSION=$2
DESCRIPTION=$3

# Strip 'v' prefix from version if present (Debian requires versions to start with a digit)
VERSION=${VERSION#v}

# Create directory structure for the package
PKG_DIR="/tmp/${BINARY_NAME}_${VERSION}"
mkdir -p ${PKG_DIR}/usr/local/bin
mkdir -p ${PKG_DIR}/DEBIAN
mkdir -p ${PKG_DIR}/lib/systemd/system
mkdir -p ${PKG_DIR}/etc/kubernetes
mkdir -p ${PKG_DIR}/etc/etcd

# Copy binary to the package directory
cp /usr/local/bin/$BINARY_NAME ${PKG_DIR}/usr/local/bin/

# Create control file
cat > ${PKG_DIR}/DEBIAN/control << EOF
Package: $BINARY_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Kubernetes Packager <maintainer@example.com>
Description: $DESCRIPTION
EOF

# Create postinst script to enable systemd service (only for services, not for CLI tools like etcdctl)
if [ "${BINARY_NAME}" != "etcdctl" ]; then
    cat > ${PKG_DIR}/DEBIAN/postinst << EOF
#!/bin/bash
if [ -d /run/systemd/system ]; then
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl enable ${BINARY_NAME}.service >/dev/null 2>&1 || true
    echo "The ${BINARY_NAME} service has been enabled. To start it, run: sudo systemctl start ${BINARY_NAME}"
fi
EOF
    chmod 755 ${PKG_DIR}/DEBIAN/postinst

    # Create prerm script to disable systemd service before removal
    cat > ${PKG_DIR}/DEBIAN/prerm << EOF
#!/bin/bash
if [ -d /run/systemd/system ]; then
    systemctl disable ${BINARY_NAME}.service >/dev/null 2>&1 || true
    systemctl stop ${BINARY_NAME}.service >/dev/null 2>&1 || true
fi
EOF
    chmod 755 ${PKG_DIR}/DEBIAN/prerm
else
    # For CLI tools, create a simpler postinst script
    cat > ${PKG_DIR}/DEBIAN/postinst << EOF
#!/bin/bash
echo "${BINARY_NAME} has been installed. You can run it from the command line."
EOF
    chmod 755 ${PKG_DIR}/DEBIAN/postinst
fi

# Copy systemd service file if it exists and if this is not etcdctl
if [ -f /systemd-units/${BINARY_NAME}.service ] && [ "${BINARY_NAME}" != "etcdctl" ]; then
    cp /systemd-units/${BINARY_NAME}.service ${PKG_DIR}/lib/systemd/system/
    echo "Copied systemd service file for ${BINARY_NAME}"
fi

# Copy configuration files based on binary name
case "$BINARY_NAME" in
    etcd)
        if [ -f /config-files/etcd.conf.yaml ]; then
            mkdir -p ${PKG_DIR}/etc/etcd
            cp /config-files/etcd.conf.yaml ${PKG_DIR}/etc/etcd/
            echo "Copied etcd config file"
        fi
        ;;
    kubelet)
        if [ -f /config-files/kubelet-config.yaml ]; then
            cp /config-files/kubelet-config.yaml ${PKG_DIR}/etc/kubernetes/
            echo "Copied kubelet config file"
        fi
        ;;
    kube-proxy)
        if [ -f /config-files/kube-proxy-config.yaml ]; then
            cp /config-files/kube-proxy-config.yaml ${PKG_DIR}/etc/kubernetes/
            echo "Copied kube-proxy config file"
        fi
        ;;
    *)
        # No specific config files for other binaries
        ;;
esac

# Create the package
echo "Building Debian package for ${BINARY_NAME}..."
dpkg-deb --build ${PKG_DIR}
echo "Package build completed"

# Move the package to the output directory
mkdir -p /output
echo "Moving package to output directory..."
mv ${PKG_DIR}.deb /output/${BINARY_NAME}_${VERSION}_amd64.deb

# Verify the package exists
if [ -f "/output/${BINARY_NAME}_${VERSION}_amd64.deb" ]; then
    echo "Package successfully created at /output/${BINARY_NAME}_${VERSION}_amd64.deb"
else
    echo "ERROR: Package creation failed!"
    exit 1
fi

# Ensure the output directory is accessible
chmod -R 777 /output

echo "Package created: /output/${BINARY_NAME}_${VERSION}_amd64.deb"
ls -la /output

# Create a symlink in the root directory for easier access by the entrypoint script
cp /output/${BINARY_NAME}_${VERSION}_amd64.deb /${BINARY_NAME}_${VERSION}_amd64.deb
chmod 644 /${BINARY_NAME}_${VERSION}_amd64.deb
echo "Copied package to: /${BINARY_NAME}_${VERSION}_amd64.deb"
