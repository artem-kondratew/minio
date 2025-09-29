#!/bin/bash


if [[ $# -ne 1 ]]
then
    echo "usage: bash install.sh <minio_mount_dir>"
    exit 1
fi

# DOCKER & SYSTEMD TEMPLATES UPDATE
MINIO_MOUNT_DIR=$1

mkdir ./data
mkdir -p $MINIO_MOUNT_DIR

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

# MINIO PASSWD SETUP
while true; do
    read -p "Enter MinIO root username (>= 3 chars): " MINIO_ROOT_USER
    if [[ ${#MINIO_ROOT_USER} -lt 3 ]]; then
        echo "Error: username must be at least 3 characters long."
    else
        break
    fi
done

while true; do
    read -s -p "Enter MinIO root password (>= 8 chars): " MINIO_ROOT_PASSWORD
    echo
    if [[ ${#MINIO_ROOT_PASSWORD} -lt 8 ]]; then
        echo "Error: password must be at least 8 characters long."
    else
        break
    fi
done

touch .env
echo "MINIO_ROOT_USER=$MINIO_ROOT_USER" > .env
echo "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" >> .env

# MINIO MOUNT SERVICE PREPARING
touch .minio_pass
echo "$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD" > .minio_pass
chmod 600 .minio_pass

# SYSTEMD CONFIGURATION
sudo mv ./minio-compose.service /etc/systemd/system/
sudo mv ./minio-mount.service /etc/systemd/system/

sudo systemctl daemon-reload

sudo systemctl enable --now minio-compose.service
sudo systemctl enable --now minio-mount.service

# SAVING MINIO MOUNT DIR PATH
touch minio_mount_dir.txt
echo $MINIO_MOUNT_DIR > minio_mount_dir.txt

rm -rf docker-compose.yaml
