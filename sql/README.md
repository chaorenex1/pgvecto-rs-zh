# SQL scripts

This directory contains two kinds of scripts:

- `inspection.sql` - one-shot instance inspection for config, extensions, and runtime stats
- `extensions/*.sql` - per-extension smoke tests

Run from the repository root, for example:

```bash
docker compose exec postgres psql -U postgres -d postgres -f /runtime/sql/inspection.sql
```

Run all extension smoke tests:

```bash
docker compose exec postgres psql -U postgres -d postgres -f /runtime/sql/extensions/00-run-all.sql
```

Run the cleanup assertion after smoke tests:

```bash
docker compose exec postgres psql -U postgres -d postgres -f /runtime/sql/extensions/99-cleanup-check.sql
```

Run a single extension test:

```bash
docker compose exec postgres psql -U postgres -d postgres -f /runtime/sql/extensions/09-postgis.sql
```

Run the full check pipeline from the host:

```bash
bash scripts/check.sh
```

On PowerShell:

```powershell
.\scripts\check.ps1
```
