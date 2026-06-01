# Frontend redeploy (production)

Production: **http://54.173.215.201/** · API base: **`http://54.173.215.201/cinebuzz`**

---

## One-time setup on EC2 (Instance Connect) — do this once

You already cloned `cinebuzz-frontend`. Link the redeploy script:

```bash
git clone https://github.com/Cinebuzz-MovieMania/cinebuzz-infra.git ~/cinebuzz-infra 2>/dev/null || true
chmod +x ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh
ln -sf ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh ~/deploy-frontend.sh
```

Or run the bundled installer (clones repos if missing):

```bash
bash ~/cinebuzz-infra/scripts/ec2-one-time-setup.sh
```

(`cinebuzz-infra` must exist on EC2 — clone from GitHub or copy the repo once.)

---

## Every frontend redeploy (only 2 steps)

### 1. Mac — push code (if you use git on EC2)

```bash
cd /Users/harshagarwal/Desktop/CINEBUZZ/Frontend/cinebuzz-frontend
git push origin main
```

Skip if you only use Mac SSH deploy (builds local files, not GitHub).

### 2. EC2 — one command

```bash
~/deploy-frontend.sh
```

That runs: `git pull` → `npm build` → copy to `/var/www/cinebuzz-frontend` → reload nginx.

### 3. Mac — hard refresh browser

**http://54.173.215.201/** → **Cmd + Shift + R**

---

## From Mac (optional)

Try automatic SSH deploy; if office blocks port 22, it prints the EC2 one-liner:

```bash
cd /Users/harshagarwal/Desktop/CINEBUZZ
./cinebuzz-infra/scripts/deploy-frontend.sh
```

When **home / hotspot** (SSH works), this alone is enough:

```bash
./cinebuzz-infra/scripts/deploy-frontend-ec2.sh
```

---

## Cheat sheet

| When | Command |
|------|---------|
| **First time on EC2** | `ln -sf ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh ~/deploy-frontend.sh` |
| **Every redeploy (office)** | EC2: `~/deploy-frontend.sh` |
| **Every redeploy (SSH works)** | Mac: `./cinebuzz-infra/scripts/deploy-frontend-ec2.sh` |
| **Before EC2 deploy** | Mac: `git push` (frontend repo) |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `~/deploy-frontend.sh` not found | Run one-time setup above |
| Old UI | Hard refresh browser |
| `git pull` no changes | `git push` from Mac first |
| Poster **413** | Nginx `client_max_body_size 10M` in `nginx/cinebuzz.conf` |
