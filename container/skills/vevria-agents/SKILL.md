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

### Spawn a task agent
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents" \
  -d '{
    "name": "agent-name",
    "role": "task",
    "prompt": "Your task instructions here. Be specific about what the agent should do and what output you expect.",
    "task_id": "optional-kanban-task-id",
    "timeout_minutes": 30
  }'
```

### Send a message to an agent
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID/message" \
  -d '{"content": "Additional instructions or context"}'
```

### Stop an agent
```bash
curl -s -X POST -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID/stop"
```

### Get agent output/result
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/agents/$AGENT_ID/result"
```

## Agent roles
- `task` — Short-lived agent for a specific task. Stops when done or on timeout.
- `service` — Long-running agent that handles ongoing work (e.g., monitoring, support).

## Guidelines
- Write clear, specific prompts — the task agent only knows what you tell it
- Set reasonable timeouts — most tasks should complete in 10-30 minutes
- Link agents to kanban tasks via `task_id` so progress is tracked
- Check agent results before marking kanban tasks as done
- Stop agents that are stuck or no longer needed
- Prefer spawning task agents over doing everything yourself — delegate parallelizable work
