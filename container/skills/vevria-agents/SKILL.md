---
name: vevria-agents
description: Spawn and manage task agents — create short-lived agents for specific tasks, monitor their progress, and collect results. Use when work should be delegated to a sub-agent.
---

# Agent Management

Spawn and manage task agents that run in their own containers to handle specific work items.

## API Base URL
`$VEVRIA_API_URL` (set in environment)

## Authentication
Include header: `x-internal-key: $VEVRIA_INTERNAL_KEY`

## Endpoints

### List agents
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents"
```

### Get agent details
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID"
```

### Create an agent
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents" \
  -d '{
    "name": "agent-name",
    "agent_type": "task",
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 8192,
    "system_prompt": "Your task instructions here.",
    "skills": ["code-editing", "web-search"],
    "capabilities": {"github_repos": true, "chat": true},
    "template_id": "optional-template-uuid"
  }'
```

### Update an agent
```bash
curl -s -X PUT -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID" \
  -d '{"name": "new-name", "model": "claude-sonnet-4-20250514"}'
```

### Start an agent
```bash
curl -s -X POST -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID/start"
```

### Stop an agent
```bash
curl -s -X POST -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID/stop"
```

### Delete an agent
```bash
curl -s -X DELETE -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID"
```

## Agent types
- `task` — Short-lived agent for a specific task. Stops when done or on timeout.
- `always_on` — Long-running agent that handles ongoing work (e.g., CEO, monitoring).

## Guidelines
- Write clear, specific system prompts — the task agent only knows what you tell it
- Use `agent_type: "task"` for short-lived work, `always_on` for persistent agents
- Check agent status before starting — an already-running agent will error
- Stop agents that are stuck or no longer needed
- Prefer spawning task agents over doing everything yourself — delegate parallelizable work
