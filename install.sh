#!/bin/bash


# CHECKING ARGUMENTS
if [[ $# -ne 1 ]]
then
    echo "usage: bash install.sh <minio_mount_dir>"
    exit 1
fi

# DOCKER & SYSTEMD TEMPLATES UPDATE
MINIO_MOUNT_DIR=$1

# CREATING DIRECTORIES
[ ! -d ./data ] && mkdir ./data
[ ! -d "$MINIO_MOUNT_DIR" ] && mkdir -p "$MINIO_MOUNT_DIR"

# USING TEMPLATES
cp docker-compose.yaml.template docker-compose.yaml
cp minio-compose.service.template minio-compose.service
cp minio-mount.service.template minio-mount.service

sed -i "s|{{MINIO_DATA_DIR}}|$PWD/data|g" ./docker-compose.yaml
sed -i "s|{{MINIO_DIR}}|$PWD|g" ./minio-compose.service
sed -i "s|{{MINIO_DIR}}|$PWD|g" ./minio-mount.service
sed -i "s|{{MINIO_MOUNT_DIR}}|$MINIO_MOUNT_DIR|g" ./minio-mount.service

# DEPS INSTALLATION
sudo apt update -y
sudo apt install -y s3fs

# SYSTEMD CONFIGURATION
chmod +x ./minio_mount.sh

sudo mv ./minio-compose.service /etc/systemd/system/
sudo mv ./minio-mount.service /etc/systemd/system/

sudo systemctl daemon-reload

sudo systemctl enable --now minio-compose.service
sudo systemctl enable --now minio-mount.service

# SAVING MINIO MOUNT DIR PATH
touch minio_mount_dir.txt
echo $MINIO_MOUNT_DIR > minio_mount_dir.txt

rm -rf docker-compose.yaml
