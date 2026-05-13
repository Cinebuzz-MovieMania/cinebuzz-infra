# Troubleshooting

Common deploy and runtime issues, with the fix.

## SSH and key issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Permission denied (publickey)` | Wrong user for the AMI | Use `ec2-user` for Amazon Linux, `ubuntu` for Ubuntu. Update `DEPLOY_USER` in `env/deploy.env`. |
| `Permissions 0644 for key are too open` | `.pem` is world-readable | `chmod 600 ~/.ssh/your-key.pem` |
| `No such file or directory` for the key | Wrong path in `DEPLOY_KEY` | `find ~ -name "*.pem" 2>/dev/null` to locate, fix path. |
| SSH timeout | Security group missing port 22 from your IP | Add inbound rule for TCP 22. |

## Deploy script errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Missing env/deploy.env` | Never copied template | `cp env/deploy.env.example env/deploy.env` and fill it. |
| `DEPLOY_KEY file not found` | Path wrong or key not on this Mac | Fix path or move the `.pem` into `~/.ssh/`. |
| Script hangs at SSH step | `sudo` is asking for a password on the server | Add the `NOPASSWD` rule (see `ec2-setup.md` step 6). |
| `nginx: [emerg] …` on reload | Bad config in `/etc/nginx/sites-enabled/cinebuzz` | `sudo nginx -t` to see the line, fix on the server, reload. |

## Backend runtime

| Symptom | Cause | Fix |
|---------|-------|-----|
| Service flaps (`systemctl status` shows restarts) | App crashes on startup | `sudo journalctl -u cinebuzz -n 200 --no-pager` to read logs. |
| `Unknown database 'cinebuzz'` | Schema not created in MySQL | Create it: `CREATE DATABASE cinebuzz CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;` |
| `Illegal base64 character '\n'` for JWT | `JWT_SECRET` has a newline | Re-set `JWT_SECRET` in `/etc/cinebuzz.env` as a single line, restart service. |
| 500 on `R2` upload | Missing `R2_*` env vars | Fill them in `/etc/cinebuzz.env`, restart service. |
| Mail not sending | Wrong `SPRING_MAIL_PASSWORD` (Gmail App Password required) or 2FA off | Fix env, restart service. |

## Frontend runtime

| Symptom | Cause | Fix |
|---------|-------|-----|
| Site loads but API calls go to `localhost:8010` | `VITE_API_BASE` wasn’t set when building | Set `VITE_API_BASE` in `env/deploy.env`, redeploy. |
| Old UI after deploy | Browser cache | Hard refresh `Cmd + Shift + R`. If it persists, check the `index-<hash>.js` filename in `<head>` — if it didn’t change, the build was the same. |
| 404 on deep links (e.g. `/admin/movies/3`) | Nginx not falling back to `index.html` | The provided `nginx/cinebuzz.conf` has `try_files $uri $uri/ /index.html;` — make sure that block is present. |

## Manual rollback

There is no automated rollback yet. If a deploy breaks production:

**Frontend:** keep the previous `dist/` tarball locally and re-run the install part:

```bash
scp -i KEY previous-dist.tar.gz ubuntu@HOST:/tmp/cinebuzz-frontend-dist.tar.gz
ssh -i KEY ubuntu@HOST 'sudo rm -rf /var/www/cinebuzz-frontend && \
  sudo mkdir -p /var/www/cinebuzz-frontend && \
  sudo tar -xzf /tmp/cinebuzz-frontend-dist.tar.gz -C /var/www/cinebuzz-frontend && \
  sudo chown -R www-data:www-data /var/www/cinebuzz-frontend && \
  sudo nginx -t && sudo systemctl reload nginx'
```

**Backend:** keep the previous JAR locally:

```bash
scp -i KEY previous-app.jar ubuntu@HOST:/tmp/app.jar
ssh -i KEY ubuntu@HOST 'sudo mv /tmp/app.jar /home/ubuntu/app.jar && \
  sudo systemctl restart cinebuzz'
```

A future improvement: have the deploy scripts copy the **current** artifact aside as `app.jar.previous` / `cinebuzz-frontend.previous` before overwriting, then add a `rollback.sh`.

## Where logs live on EC2

| What | Where |
|------|-------|
| Backend (Spring Boot via systemd) | `sudo journalctl -u cinebuzz -f` |
| Nginx access | `/var/log/nginx/access.log` |
| Nginx errors | `/var/log/nginx/error.log` |
| System | `sudo dmesg -T`, `sudo journalctl -xe` |
