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

## Deployments

### List deployments
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deployments"
```

### Get deployment status
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deployments/$DEPLOYMENT_ID"
```

### Trigger a deploy
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deploy" \
  -d '{"service_name": "my-service", "repo": "org/repo-name", "branch": "main"}'
```

### Redeploy a service
```bash
curl -s -X POST -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deployments/$DEPLOYMENT_ID/redeploy"
```

### Get deployment logs
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deployments/$DEPLOYMENT_ID/logs?lines=100"
```

## GitHub Repositories

### List repos
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/repos"
```

### Create a repo from template
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/repos" \
  -d '{"name": "repo-name", "template": "default", "private": true}'
```

## Databases

### List databases
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/databases"
```

### Provision a database
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/databases" \
  -d '{"type": "postgres", "name": "my-db"}'
```

## Environment Variables

### List env vars for a service
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deployments/$DEPLOYMENT_ID/env"
```

### Set env vars
```bash
curl -s -X PUT -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/infra/deployments/$DEPLOYMENT_ID/env" \
  -d '{"DATABASE_URL": "postgres://...", "API_KEY": "..."}'
```

## Guidelines
- Check deployment status after triggering deploys — do not assume success
- Read logs when a deployment fails before retrying
- Use templates when creating repos to maintain consistency
- Never expose secrets in chat — use env vars for credentials
- Prefer redeploying over creating new deployments for existing services
