# MinIO setup

This project sets up MinIO via Docker Compose and automatically mounts a bucket using ```s3fs```.


---

## Step 1: Install deps


```bash
sudo apt update -y && sudo apt install -y s3fs
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
