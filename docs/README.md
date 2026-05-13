# cinebuzz-infra — docs

Server templates and helper scripts for running **Cinebuzz** on a single Ubuntu EC2 instance.

- **Nginx** site (`/cinebuzz/` → API on `:8010`, `/` → static SPA)
- **systemd** unit (`cinebuzz.service`) running the Spring Boot JAR
- **Env file** template for `/etc/cinebuzz.env`
- **Deploy scripts** that build on your Mac and ship to EC2

This repository contains **no secrets**.

## Index

| Doc | Purpose |
|-----|---------|
| [`ec2-setup.md`](./ec2-setup.md) | One-time server bootstrap (Nginx, systemd, env, ports) |
| [`deploy-scripts.md`](./deploy-scripts.md) | What the two scripts do and how to use them |
| [`troubleshooting.md`](./troubleshooting.md) | Common failures and fixes |

> Architecture overview, full deployment story, and runbook live in the central docs repo. This folder is for things specific to the infra repo.
