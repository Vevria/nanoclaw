---
name: vevria-infra
description: Manage company infrastructure — deploy services, create GitHub repos, provision databases, and check deployment status. Use when the agent needs to manage cloud resources.
---

# Infrastructure Management

Manage Railway deployments, GitHub repositories, and databases for the company.

## API Base URL
`$VEVRIA_API_URL` (set in environment)

## Authentication
Include header: `x-internal-key: $VEVRIA_INTERNAL_KEY`

## Provision Infrastructure

### Initial provisioning (creates Railway project + default database)
```bash
curl -s -X POST -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/provision"
```

### Get current infrastructure status
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra"
```

## GitHub Repositories

### Create a repo (optionally from template)
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/repos" \
  -d '{"name": "repo-name", "description": "Description", "template": {"owner": "org", "repo": "template-repo"}}'
```

## Databases

### Provision a database
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/databases" \
  -d '{"name": "my-db", "db_type": "postgresql"}'
```

## Logs

### Get logs for a service
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/logs/$SERVICE_ID"
```

## Deployments

### Deploy a service
```bash
curl -s -X POST -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deploy/$SERVICE_ID"
```

## Guidelines
- Always provision infrastructure before creating repos or databases
- Check infrastructure status after provisioning — do not assume success
- Read logs when a deployment fails before retrying
- Use templates when creating repos to maintain consistency
- Never expose secrets in chat — use env vars for credentials
