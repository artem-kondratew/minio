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


# GENERATE ROOT CREDENTIALS
echo "Enter MinIO root username:"
read MINIO_ROOT_USER
echo "Enter MinIO root password:"
read -s MINIO_ROOT_PASSWORD

# SAVE CREDENTIALS
CRED_FILE="$PWD/.minio_credentials"
echo "MINIO_ROOT_USER=$MINIO_ROOT_USER" | sudo tee $CRED_FILE > /dev/null
echo "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" | sudo tee -a $CRED_FILE > /dev/null
sudo chmod 600 $CRED_FILE

# Save credentials for s3fs
CRED_FILE_MOUNT="$PWD/.minio_credentials_mount"
echo "$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD" | sudo tee $CRED_FILE_MOUNT > /dev/null
sudo chmod 600 $CRED_FILE_MOUNT

# SYSTEMD CONFIGURATION
sudo mv ./minio-compose.service /etc/systemd/system/
sudo mv ./minio-mount.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now minio-compose.service
sudo systemctl enable --now minio-mount.service

# SAVING MINIO MOUNT DIR PATH
touch minio_mount_dir.txt
echo $MINIO_MOUNT_DIR > minio_mount_dir.txt
