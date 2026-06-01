# RDS MySQL and DBeaver

Production uses **AWS RDS MySQL 8** in the same VPC as EC2. The Spring app reads credentials from `/etc/cinebuzz.env`.

## Naming rules (important)

| AWS / CLI | MySQL database name |
|-----------|---------------------|
| DB instance identifier can be `cinebuzz-db` (hyphen OK) | **`cinebuzzdb`** — RDS `--db-name` must be **letters and numbers only** (no hyphens) |

JDBC URL must match the real database name:

```text
jdbc:mysql://<RDS_ENDPOINT>:3306/cinebuzzdb
```

## Current production reference (us-east-1)

Update these if you recreate RDS.

| Item | Value |
|------|--------|
| RDS endpoint | `cinebuzz-db.csfgq2ecqa5b.us-east-1.rds.amazonaws.com` |
| Port | `3306` |
| Database | `cinebuzzdb` |
| EC2 public IP (website) | `54.173.215.201` |
| EC2 security group | `sg-061aa64011d2e8f26` |
| RDS security group | `sg-0935db70cbbd5f239` (`cinebuzz-rds-sg`) |
| VPC | `vpc-0b3546a9f0c22d29f` |

## RDS security group inbound (3306)

| Source | Purpose |
|--------|---------|
| `sg-061aa64011d2e8f26` | Cinebuzz backend on EC2 |
| `<YOUR_MAC_PUBLIC_IP>/32` | DBeaver from your laptop — get IP on the **Mac**: `curl -s https://checkip.amazonaws.com` (not CloudShell) |

Do **not** use the EC2 public IP (`54.173.215.201`) as the DBeaver source CIDR.

## `/etc/cinebuzz.env` on EC2

```bash
SPRING_DATASOURCE_URL=jdbc:mysql://cinebuzz-db.csfgq2ecqa5b.us-east-1.rds.amazonaws.com:3306/cinebuzzdb
SPRING_DATASOURCE_USERNAME=admin
SPRING_DATASOURCE_PASSWORD=<your-secret>
```

Then:

```bash
sudo systemctl restart cinebuzz
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8010/cinebuzz/v3/api-docs
```

## DBeaver (direct, no SSH)

| Field | Value |
|--------|--------|
| Host | RDS endpoint |
| Port | `3306` |
| Database | `cinebuzzdb` |
| SSH | Off |

Driver properties if needed: `useSSL=false`, `allowPublicKeyRetrieval=true`.

## Recreate RDS via CLI (CloudShell)

See commands in repo history or run with:

- `--db-name cinebuzzdb` (not `cinebuzz-db`)
- `--publicly-accessible`
- `--vpc-security-group-ids sg-0935db70cbbd5f239`
- `--db-subnet-group-name default`

## Empty database after recreate

Tables are created by Spring (`ddl-auto: update`) on first successful start. **Data** (users, movies, etc.) must be re-seeded via the admin UI.

## If deploy SSH times out (Instance Connect)

On **EC2 Instance Connect** for `54.173.215.201`:

**Nginx** (`client_max_body_size 10M` for poster uploads):

```bash
sudo nano /etc/nginx/sites-available/cinebuzz
# Under location /cinebuzz/ { add: client_max_body_size 10M;
sudo nginx -t && sudo systemctl reload nginx
```

Or paste the full file from `cinebuzz-infra/nginx/cinebuzz.conf` in the repo.

**Backend env** — use `env/cinebuzz.env.production.example` as a guide, then `sudo systemctl restart cinebuzz`.
