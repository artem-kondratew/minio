#!/bin/bash

# CHECKING ARGUMENTS
if [[ $# -ne 1 ]]; then
    echo "usage: bash install.sh <parquets_dir>"
    exit 1
fi

PARQUETS_DIR=$(realpath "$1")

# GENERATE ROOT CREDENTIALS
while true; do
    echo "Enter MinIO root username (min 3 characters):"
    read MINIO_ROOT_USER
    [[ ${#MINIO_ROOT_USER} -ge 3 ]] && break
    echo "Error: username must be at least 3 characters."
done

while true; do
    echo "Enter MinIO root password (min 8 characters):"
    read -s MINIO_ROOT_PASSWORD
    echo ""
    [[ ${#MINIO_ROOT_PASSWORD} -ge 8 ]] && break
    echo "Error: password must be at least 8 characters."
done

if [ -d "$PARQUETS_DIR" ] && [ "$(ls -A "$PARQUETS_DIR" 2>/dev/null)" ]; then
    echo "Error: $PARQUETS_DIR is not empty. Please provide an empty directory."
    exit 1
fi

echo "Starting installation..."

# CREATING DIRECTORIES
[ ! -d ./data ] && mkdir ./data
[ ! -d "$PARQUETS_DIR" ] && mkdir -p "$PARQUETS_DIR"

# USING TEMPLATES
cp docker-compose.yaml.template docker-compose.yaml
cp minio-compose.service.template minio-compose.service
cp minio-mount.service.template minio-mount.service

sed -i "s|{{MINIO_DATA_DIR}}|$PWD/data|g" ./docker-compose.yaml
sed -i "s|{{MINIO_DIR}}|$PWD|g" ./minio-compose.service
sed -i "s|{{MINIO_DIR}}|$PWD|g" ./minio-mount.service
sed -i "s|{{MINIO_MOUNT_DIR}}|$PARQUETS_DIR|g" ./minio-mount.service

# SAVE CREDENTIALS
CRED_FILE="$PWD/.minio_credentials"
echo "MINIO_ROOT_USER=$MINIO_ROOT_USER" | sudo tee $CRED_FILE > /dev/null
echo "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" | sudo tee -a $CRED_FILE > /dev/null
sudo chmod 600 $CRED_FILE

CRED_FILE_MOUNT="$PWD/.minio_credentials_mount"
echo "$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD" | sudo tee $CRED_FILE_MOUNT > /dev/null
sudo chmod 600 $CRED_FILE_MOUNT

# SYSTEMD CONFIGURATION
sudo mv ./minio-compose.service /etc/systemd/system/
sudo mv ./minio-mount.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable minio-compose.service
sudo systemctl restart minio-compose.service

# WAIT FOR MINIO
echo "Waiting for MinIO to start..."
for i in $(seq 1 30); do
    curl -sf http://127.0.0.1:9000/minio/health/live > /dev/null 2>&1 && break
    sleep 1
done

if ! curl -sf http://127.0.0.1:9000/minio/health/live > /dev/null 2>&1; then
    echo "Error: MinIO did not start in time. Check: journalctl -xeu minio-compose.service"
    exit 1
fi

# MOUNT BUCKET
sudo systemctl enable minio-mount.service
sudo systemctl restart minio-mount.service

# SAVING MINIO MOUNT DIR PATH
echo "$PARQUETS_DIR" > minio_mount_dir.txt

# DETECT VPN IP
VPN_IP=$(ip -br a 2>/dev/null \
    | grep -v -E '^(lo|en|eth|wl|docker|br-|veth)' \
    | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
    | head -1)

if [ -n "$VPN_IP" ]; then
    echo "Configuring iptables for VPN local access..."
    sudo iptables -t nat -I OUTPUT -d "$VPN_IP" -p tcp --dport 9000 -j DNAT --to-destination 127.0.0.1:9000
    sudo iptables -t nat -I OUTPUT -d "$VPN_IP" -p tcp --dport 9001 -j DNAT --to-destination 127.0.0.1:9001
    if command -v netfilter-persistent &>/dev/null; then
        sudo netfilter-persistent save
    else
        sudo apt-get install -y iptables-persistent
        sudo netfilter-persistent save
    fi
    echo ""
    echo "MinIO installed successfully!"
    echo "  Console: http://$VPN_IP:9001"
    echo "  API:     http://$VPN_IP:9000"
else
    echo ""
    echo "MinIO installed successfully!"
    echo "  Console: http://localhost:9001"
    echo "  API:     http://localhost:9000"
fi
echo "  Bucket: data"
echo "  Mounted at: $PARQUETS_DIR"
