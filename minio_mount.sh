#!/bin/bash


export GNUPGHOME=/root/.gnupg

MOUNT_DIR="$1"

MINIO_ROOT_USER=$(pass minio/root_username)
MINIO_ROOT_PASSWORD=$(pass minio/root_passwd)

CRED_FILE=$(mktemp)
echo "$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD" > "$CRED_FILE"
chmod 600 "$CRED_FILE"

until docker exec minio mc alias set local http://127.0.0.1:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"; do
    sleep 1
done

/usr/bin/s3fs data "$MOUNT_DIR" -f -o passwd_file="$CRED_FILE" -o url=http://127.0.0.1:9000 -o use_path_request_style -o nonempty -o allow_other

rm -f "$CRED_FILE"
