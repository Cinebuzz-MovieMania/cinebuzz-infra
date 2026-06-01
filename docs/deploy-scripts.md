# Deploy scripts

Scripts under [`scripts/`](../scripts/) for deploy and nginx sync:

| Script | What it ships |
|--------|---------------|
| [`deploy-frontend-ec2.sh`](../scripts/deploy-frontend-ec2.sh) | New `dist/` for the SPA |
| [`deploy-backend-ec2.sh`](../scripts/deploy-backend-ec2.sh) | New JAR for the Spring app |
| [`sync-nginx-ec2.sh`](../scripts/sync-nginx-ec2.sh) | Push `nginx/cinebuzz.conf` and reload |

Both deploy scripts read configuration from [`env/deploy.env`](../env/deploy.env.example) (gitignored).

## 1. One-time: create `env/deploy.env`

```bash
cd cinebuzz-infra
cp env/deploy.env.example env/deploy.env
```

Edit `env/deploy.env`:

```bash
DEPLOY_HOST=54.173.215.201
DEPLOY_USER=ubuntu
DEPLOY_KEY=/Users/<you>/.ssh/cinebuzz-movie.pem
VITE_API_BASE=http://54.173.215.201/cinebuzz
```

Use the **public IP** for `DEPLOY_HOST` if office DNS resolves `ec2-*.amazonaws.com` to a proxy.

```bash
# placeholder if you prefer hostname:
# DEPLOY_HOST=ec2-XX-XX-XX-XX.compute-1.amazonaws.com
```

> `DEPLOY_KEY` must point at the **private** `.pem` on your machine; the file should be `chmod 600`.

## 2. Run a deploy

The scripts work from anywhere — they resolve paths relative to themselves.

**Frontend:**

```bash
./cinebuzz-infra/scripts/deploy-frontend-ec2.sh
```

What it does:

1. `npm ci` + `npm run build` in `Frontend/cinebuzz-frontend` with your `VITE_API_BASE`.
2. `tar -czf` the `dist/` contents.
3. `scp` the tarball to `/tmp/` on the server.
4. SSH:
   - Wipe `/var/www/cinebuzz-frontend`.
   - Untar into it.
   - `chown` to `www-data`.
   - `nginx -t && systemctl reload nginx`.

**Backend:**

```bash
./cinebuzz-infra/scripts/deploy-backend-ec2.sh
```

What it does:

1. `./mvnw -DskipTests clean package` in `Backend/cinebuzz-backend`.
2. Stage `target/cinebuzz-0.0.1-SNAPSHOT.jar` as `/tmp/cinebuzz-release.jar`.
3. `scp` it to the server.
4. SSH:
   - `mv` it to `/home/ubuntu/app.jar`.
   - `systemctl restart cinebuzz`.
   - `systemctl is-active cinebuzz` (prints `active`).

## 3. Verify

After either deploy, from your Mac:

```bash
curl -sI http://<EC2_HOST>/cinebuzz/v3/api-docs   # backend
curl -sI http://<EC2_HOST>/                       # frontend
```

In the browser do a **hard refresh** (`Cmd + Shift + R`) so cached JS/CSS is replaced.

## 4. Layout the scripts assume

```
<repo-root>/
  Backend/cinebuzz-backend/
  Frontend/cinebuzz-frontend/
  cinebuzz-infra/
    env/deploy.env
    scripts/deploy-frontend-ec2.sh
    scripts/deploy-backend-ec2.sh
```

If your folders sit elsewhere, change `BE`/`FE` in the scripts or symlink.

## 5. What the scripts intentionally don’t do

- They **do not** run server bootstrap (Nginx, systemd, env). That’s `ec2-setup.md`, done once.
- They **do not** push to GitHub. Commit + push separately.
- They **do not** roll back. See `troubleshooting.md` for manual rollback notes.
