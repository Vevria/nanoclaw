---
name: vevria-kanban
description: Manage the company's kanban board — create, update, move, and assign tasks. Use when the agent needs to manage work items.
---

# Kanban Board Management

You have access to the company's kanban board via the Vevria API.

## API Base URL
`$VEVRIA_API_URL` (set in environment)

## Authentication
Include header: `x-internal-key: $VEVRIA_INTERNAL_KEY`

## Endpoints

### List all tasks
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/tasks"
```

### Create a task
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/tasks" \
  -d '{"title": "Task title", "description": "Details", "column": "todo", "priority": "medium", "assigned_to": "agent-name"}'
```

### Update a task (move columns, change status)
```bash
curl -s -X PUT -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/tasks/$TASK_ID" \
  -d '{"column": "in_progress"}'
```

### Delete a task
```bash
curl -s -X DELETE -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/tasks/$TASK_ID"
```

## Column values
`backlog`, `todo`, `in_progress`, `review`, `done`

## Priority values
`low`, `medium`, `high`, `critical`

## Guidelines
- Break large work items into small, specific tasks
- Move tasks through columns as you make progress
- Set appropriate priority — use `critical` sparingly
- Assign tasks to yourself or other agents by name
- Add clear descriptions so other agents (or the owner) understand the work
