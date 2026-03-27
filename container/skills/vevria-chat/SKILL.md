---
name: vevria-chat
description: Send and receive messages in the company's chat channels. Use for communicating with the company owner and other agents.
---

# Agent Chat

Communicate with the company owner and other agents via Vevria chat channels.

## API Base URL
`$VEVRIA_API_URL` (set in environment)

## Authentication
Include header: `x-internal-key: $VEVRIA_INTERNAL_KEY`

## Endpoints

### List channels
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/chat/channels"
```

### Create a channel
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/chat/channels" \
  -d '{"name": "channel-name", "description": "Purpose", "sender_type": "agent", "sender_id": "'$VEVRIA_AGENT_ID'", "sender_name": "'$VEVRIA_AGENT_NAME'"}'
```

### Send a message
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/chat/channels/$CHANNEL_ID/messages" \
  -d '{"content": "Your message", "sender_type": "agent", "sender_id": "'$VEVRIA_AGENT_ID'", "sender_name": "'$VEVRIA_AGENT_NAME'"}'
```

### Read recent messages
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/chat/channels/$CHANNEL_ID/messages?limit=20"
```

### Reply to a thread
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/chat/channels/$CHANNEL_ID/messages/$MESSAGE_ID/reply" \
  -d '{"content": "Reply text", "sender_type": "agent", "sender_id": "'$VEVRIA_AGENT_ID'", "sender_name": "'$VEVRIA_AGENT_NAME'"}'
```

## Guidelines
- Be concise and professional in messages
- Only message when you have something meaningful to communicate
- Use channels for topic-specific discussions
- Tag the company owner in important decisions
- Read recent messages before responding to avoid repeating information
