# EC2 setup (one-time)

You only do this when standing up a **new** server (or after wiping one).

## 0. Provision

- Ubuntu 22.04 / 24.04 EC2 instance (t3.small or above is comfortable).
- Security group inbound: **22** (your IP), **80** (anywhere), **443** (anywhere if/when you add TLS).
- An RDS MySQL in the **same VPC** as EC2 — see [RDS and DBeaver](rds-and-dbeaver.md).
- Optional: Elastic IP so the public address doesn’t change on reboot.

SSH in:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<EC2_HOST>
```

## 1. Install runtime

```bash
sudo apt update
sudo apt install -y openjdk-21-jre-headless nginx redis-server
sudo systemctl enable --now redis-server
java -version    # confirm 21
```

## 2. Place the env file

Copy [`env/cinebuzz.env.example`](../env/cinebuzz.env.example) onto the server and fill in real values:

```bash
sudo nano /etc/cinebuzz.env
sudo chmod 600 /etc/cinebuzz.env
```

The file is a flat list of `KEY=VALUE` lines (DB, JWT, R2, mail, Redis). systemd reads it.

For production RDS, start from [`env/cinebuzz.env.production.example`](../env/cinebuzz.env.production.example) (database name **`cinebuzzdb`**, not `cinebuzz-db`).

## 3. Install the systemd unit

Copy [`systemd/cinebuzz.service`](../systemd/cinebuzz.service) onto the server:

```bash
sudo cp cinebuzz.service /etc/systemd/system/cinebuzz.service
sudo systemctl daemon-reload
sudo systemctl enable cinebuzz
```

The unit expects the JAR at `/home/ubuntu/app.jar`. The first deploy puts it there. To start it now (without the app jar yet) skip the start; otherwise:

```bash
sudo systemctl start cinebuzz
sudo systemctl status cinebuzz
```

## 4. Install the Nginx site

Copy [`nginx/cinebuzz.conf`](../nginx/cinebuzz.conf) onto the server:

```bash
sudo cp cinebuzz.conf /etc/nginx/sites-available/cinebuzz
sudo ln -sf /etc/nginx/sites-available/cinebuzz /etc/nginx/sites-enabled/cinebuzz
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

This site:
- Listens on port 80.
- Serves `/var/www/cinebuzz-frontend` on `/`.
- Proxies `/cinebuzz/` → `127.0.0.1:8010/cinebuzz/` (your Spring app).

## 5. Create the static frontend root

```bash
sudo mkdir -p /var/www/cinebuzz-frontend
sudo chown -R www-data:www-data /var/www/cinebuzz-frontend
```

The first frontend deploy will fill it.

## 6. Allow passwordless `sudo` for deploys (recommended)

The deploy scripts run `sudo` for `mv`, `tar`, `chown`, `systemctl`, and `nginx`. Add a dedicated rule:

```bash
sudo visudo -f /etc/sudoers.d/cinebuzz-deploy
```

Paste:

```text
ubuntu ALL=(ALL) NOPASSWD: /bin/mv, /bin/tar, /bin/rm, /bin/mkdir, /bin/chown, /bin/systemctl, /usr/sbin/nginx
```

Save. Now the SSH-driven deploys won’t hang on a password prompt.

## 7. First smoke test

After the **first** backend + frontend deploys, from your Mac:

```bash
curl -sI http://<EC2_HOST>/cinebuzz/v3/api-docs   # expect HTTP/1.1 200
curl -sI http://<EC2_HOST>/                       # expect HTTP/1.1 200
```

That’s it — the server is now ready for repeat deploys via the scripts.
