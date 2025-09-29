# MinIO setup

This project sets up MinIO via Docker Compose and automatically mounts a bucket using ```s3fs```.


---

## Step 1: Generate Root Username and Password

1. Switch to root:

```bash
bash sudo -i
```

2. Initialize pass for root:

```bash
gpg --full-generate-key
pass init "root (for minio)"
```

3. Create MinIO credentials:

```bash
pass insert minio/root_username
pass insert minio/root_passwd
```

4. Verify credentials:

```bash
pass list
pass show minio/root_username
pass show minio/root_passwd
```

## Step 2: Run the install script

1. Clone via ssh:

```bash
git clone git@github.com:artem-kondratew/minio.git
```

2. Clone via https:

```bash
git clone https://github.com/artem-kondratew/minio.git
```

3. Go to the directory:

```bash
cd ./minio
```

4. Run the install script:

```bash
bash ./install.sh /path/to/mount/minio
```

The installer will:
- Create data and mount directories

- Copy Docker Compose and systemd templates

- Replace placeholders with actual paths

- Install dependencies (s3fs)

- Configure and start systemd services for MinIO and bucket mounting

## Step 3: Verify the installation

1. Check `minio-compose` status:

```bash
systemctl status minio-compose.service
```


2. Check `minio-mount` status:

```bash
systemctl status minio-mount.service
```

3. Monitor logs for `minio-compose`:

```bash
journalctl -xeu minio-compose.service
```

3. Monitor logs for `minio-mount`:

```bash
journalctl -xeu minio-mount.service
```
