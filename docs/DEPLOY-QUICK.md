# Deploy quick reference

From monorepo root: `/Users/harshagarwal/Desktop/CINEBUZZ`

Requires `cinebuzz-infra/env/deploy.env` (see `env/deploy.env.example`).

| Change | Command |
|--------|---------|
| Frontend | **EC2 (office):** `~/deploy-frontend.sh` · **Mac:** `./cinebuzz-infra/scripts/deploy-frontend.sh` — see [frontend-redeploy.md](frontend-redeploy.md) |
| Backend | `./cinebuzz-infra/scripts/deploy-backend-ec2.sh` |
| Both | Run both scripts |
| Nginx only | `./cinebuzz-infra/scripts/sync-nginx-ec2.sh` |

Verify:

```bash
curl -sI http://54.173.215.201/cinebuzz/v3/api-docs
curl -sI http://54.173.215.201/
```

Hard refresh browser: **Cmd + Shift + R**.

If SSH times out, use EC2 Instance Connect — see [rds-and-dbeaver.md](rds-and-dbeaver.md).
