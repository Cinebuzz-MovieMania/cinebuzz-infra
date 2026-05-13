# cinebuzz-infra

Deployment templates for **Cinebuzz** on a single Ubuntu EC2 instance:

- **Nginx** — API under `/cinebuzz/`, static SPA under `/`
- **systemd** — Spring Boot JAR at `/home/ubuntu/app.jar`
- **Environment** — example variables for `/etc/cinebuzz.env`
- **`scripts/`** — optional local build helpers when this folder lives inside the **Cinebuzz monorepo** (`../Backend`, `../Frontend`). They are not used on EC2.

## Easy deploy from your Mac (one command)

After **one-time** EC2 setup (Nginx, systemd, `/etc/cinebuzz.env` — sections below):

1. Copy **`env/deploy.env.example`** → **`env/deploy.env`** and edit: `DEPLOY_HOST`, `DEPLOY_USER` (default `ubuntu`), **`DEPLOY_KEY`** (path to your `.pem` on this machine), and **`VITE_API_BASE`** for frontend builds (e.g. `http://YOUR_IP/cinebuzz`). **`deploy.env` is gitignored** — do not commit it.

2. From the monorepo root (parent of `cinebuzz-infra`):

   **Frontend (build + upload + Nginx reload):**

   ```bash
   ./cinebuzz-infra/scripts/deploy-frontend-ec2.sh
   ```

   **Backend (Maven + upload + `systemctl restart cinebuzz`):**

   ```bash
   ./cinebuzz-infra/scripts/deploy-backend-ec2.sh
   ```

That replaces the long manual `tar` / `scp` / SSH block for routine deploys. Infra files still define **where** files go on the server (`/var/www/cinebuzz-frontend`, `/home/ubuntu/app.jar`); the scripts **ship** new builds there.

This repository contains **no secrets**. Create real values only on the server or in your secret manager.

## Apply on EC2 (one-time)

1. Copy environment template and edit on the server:

   ```bash
   sudo cp env/cinebuzz.env.example /etc/cinebuzz.env
   sudo nano /etc/cinebuzz.env
   sudo chmod 600 /etc/cinebuzz.env
   ```

2. Install systemd unit:

   ```bash
   sudo cp systemd/cinebuzz.service /etc/systemd/system/cinebuzz.service
   sudo systemctl daemon-reload
   sudo systemctl enable cinebuzz
   ```

3. Install Nginx site (merge or replace your site config):

   ```bash
   sudo cp nginx/cinebuzz.conf /etc/nginx/sites-available/cinebuzz
   sudo ln -sf /etc/nginx/sites-available/cinebuzz /etc/nginx/sites-enabled/cinebuzz
   sudo rm -f /etc/nginx/sites-enabled/default
   sudo nginx -t && sudo systemctl reload nginx
   ```

4. Ensure JAR exists at `/home/ubuntu/app.jar` and static files at `/var/www/cinebuzz-frontend`, then:

   ```bash
   sudo systemctl start cinebuzz
   ```

## Related repositories

- Application code: `cinebuzz-backend`, `cinebuzz-frontend` (Cinebuzz-MovieMania organization).

## Create this repo on GitHub

1. Open [github.com/organizations/Cinebuzz-MovieMania/repositories/new](https://github.com/organizations/Cinebuzz-MovieMania/repositories/new) (or **New repository** under the org).
2. Repository name: **`cinebuzz-infra`**.
3. Visibility: **Private** recommended.
4. Leave **Add a README** unchecked (this repo already has one).
5. Click **Create repository**.

## Push from your Mac (first time)

```bash
cd /Users/harshagarwal/Desktop/CINEBUZZ/cinebuzz-infra
git remote add origin https://github.com/Cinebuzz-MovieMania/cinebuzz-infra.git
git push -u origin main
```

Use SSH if you prefer: `git@github.com:Cinebuzz-MovieMania/cinebuzz-infra.git`

If `git remote add` fails because `origin` exists: `git remote set-url origin <url>` then `git push -u origin main`.
