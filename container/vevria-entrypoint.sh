#!/bin/bash
# Vevria Agent Entrypoint — runs as PID 1 in the Railway container.
#
# For ALWAYS-ON agents: loops forever, processing work and checking for messages.
# For TASK agents: processes the system prompt once and exits.

set -euo pipefail

AGENT_TYPE="${AGENT_TYPE:-task}"
POLL_INTERVAL="${POLL_INTERVAL:-60}"
VEVRIA_API_URL="${VEVRIA_API_URL:?Required}"
VEVRIA_AGENT_ID="${VEVRIA_AGENT_ID:?Required}"
VEVRIA_COMPANY_ID="${VEVRIA_COMPANY_ID:?Required}"
VEVRIA_CALLBACK_URL="${VEVRIA_CALLBACK_URL:?Required}"
VEVRIA_INTERNAL_KEY="${VEVRIA_INTERNAL_KEY:-}"
SYSTEM_PROMPT="${SYSTEM_PROMPT:-You are a Vevria agent. Check the kanban board for work.}"
MODEL="${MODEL:-anthropic/claude-sonnet-4.6}"
MAX_TOKENS="${MAX_TOKENS:-8192}"

LAST_SEEN_FILE="/tmp/vevria_last_seen"
echo "1970-01-01T00:00:00Z" > "$LAST_SEEN_FILE"

HEADERS=(-H "x-internal-key: $VEVRIA_INTERNAL_KEY" -H "Content-Type: application/json")

# Send a callback to the platform
callback() {
    local content="$1"
    local in_tokens="${2:-0}"
    local out_tokens="${3:-0}"
    local cost="${4:-0}"
    # Write content to temp file to avoid shell injection in JSON construction
    local content_file=$(mktemp)
    printf '%s' "$content" > "$content_file"
    local json_content
    json_content=$(python3 -c 'import sys,json; print(json.dumps(open(sys.argv[1]).read()))' "$content_file")
    rm -f "$content_file"
    curl -s -X POST "$VEVRIA_CALLBACK_URL" \
        "${HEADERS[@]}" \
        -d "{\"agent_id\":\"$VEVRIA_AGENT_ID\",\"company_id\":\"$VEVRIA_COMPANY_ID\",\"chat_jid\":\"vevria:$VEVRIA_AGENT_ID\",\"content\":$json_content,\"input_tokens\":$in_tokens,\"output_tokens\":$out_tokens,\"cost_usd\":$cost}" \
        > /dev/null 2>&1 || true
}

trigger_redeploy() {
    echo "Triggering redeploy for company ${VEVRIA_COMPANY_ID}..."
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${VEVRIA_API_URL}/api/companies/${VEVRIA_COMPANY_ID}/infra/redeploy" \
        -H "x-internal-key: ${VEVRIA_INTERNAL_KEY}" \
        -H "Content-Type: application/json" \
        -d '{}')
    local http_code
    http_code=$(echo "$response" | tail -1)
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "Redeploy triggered successfully"
    else
        echo "Redeploy failed (HTTP $http_code) — will retry on next push"
    fi
}

check_deploy_status() {
    local response
    response=$(curl -s "${VEVRIA_API_URL}/api/companies/${VEVRIA_COMPANY_ID}/infra/deploy-status" \
        -H "x-internal-key: ${VEVRIA_INTERNAL_KEY}")
    echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin).get('data',{}); print(d.get('status','unknown') if d else 'none')" 2>/dev/null || echo "unknown"
}

# Run Claude Code with a prompt, capture output and token usage
run_claude() {
    local prompt="$1"
    local output_file=$(mktemp)

    # Pipe prompt via stdin to avoid shell injection
    printf '%s' "$prompt" | timeout 300 claude -p --model "$MODEL" \
        > "$output_file" 2>/dev/null || true

    local output=$(cat "$output_file")
    rm -f "$output_file"

    # Report back
    if [ -n "$output" ]; then
        callback "$output" "0" "0" "0"
    fi

    echo "$output"
}

# Check for new messages addressed to this agent
check_messages() {
    local last_seen=$(cat "$LAST_SEEN_FILE")
    local channel_url="$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/chat/channels"
    local channels=$(curl -s "$channel_url" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" 2>/dev/null)

    # Look for messages in all channels, filtering by last_seen timestamp
    echo "$channels" | python3 -c "
import sys, json, os
try:
    data = json.load(sys.stdin).get('data', [])
    api = os.environ['VEVRIA_API_URL']
    key = os.environ.get('VEVRIA_INTERNAL_KEY', '')
    cid = os.environ['VEVRIA_COMPANY_ID']
    aid = os.environ['VEVRIA_AGENT_ID']
    last_seen = '$last_seen'

    import urllib.request
    for ch in data:
        url = f'{api}/api/companies/{cid}/chat/channels/{ch[\"id\"]}/messages?limit=50'
        req = urllib.request.Request(url, headers={'x-internal-key': key})
        resp = urllib.request.urlopen(req, timeout=5)
        msgs = json.loads(resp.read()).get('data', [])
        for m in msgs:
            # Skip own messages and already-seen messages
            if m.get('sender_id') == aid:
                continue
            # Skip messages older than last_seen
            if m.get('created_at', '') <= last_seen:
                continue
            # Print messages that mention this agent or are in the general channel
            if ch.get('name') == 'general' or aid in m.get('content', ''):
                print(json.dumps({'channel_id': ch['id'], 'message_id': m['id'], 'content': m['content'], 'sender': m['sender_name']}))
except:
    pass
" 2>/dev/null
}

# Check kanban for assigned tasks
check_kanban() {
    local kanban_url="$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/kanban"
    curl -s "$kanban_url" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" 2>/dev/null | python3 -c "
import sys, json, os
try:
    tasks = json.load(sys.stdin).get('data', [])
    aid = os.environ.get('VEVRIA_AGENT_NAME', 'ceo')
    for t in tasks:
        if t.get('column') in ('todo', 'in_progress') and (t.get('assigned_to', '') == aid or t.get('assigned_to', '') == 'ceo-agent'):
            print(json.dumps({'id': t['id'], 'title': t['title'], 'description': t.get('description', ''), 'column': t['column']}))
except:
    pass
" 2>/dev/null
}

echo "[vevria-agent] Starting as $AGENT_TYPE agent (model=$MODEL)"
echo "[vevria-agent] Company: $VEVRIA_COMPANY_ID"
echo "[vevria-agent] Agent: $VEVRIA_AGENT_ID"

# Process the system prompt first
echo "[vevria-agent] Processing system prompt..."
run_claude "$SYSTEM_PROMPT" > /dev/null

# If task agent, we're done
if [ "$AGENT_TYPE" = "task" ]; then
    echo "[vevria-agent] Task agent complete."
    exit 0
fi

# Always-on loop
echo "[vevria-agent] Entering always-on loop (poll every ${POLL_INTERVAL}s)..."
while true; do
    sleep "$POLL_INTERVAL"

    # Check for new messages
    MESSAGES=$(check_messages)
    if [ -n "$MESSAGES" ]; then
        echo "[vevria-agent] Processing $(echo "$MESSAGES" | wc -l) new messages..."
        while IFS= read -r msg; do
            # Write message to temp file to safely extract fields without shell injection
            msg_file=$(mktemp)
            printf '%s' "$msg" > "$msg_file"
            content=$(python3 -c "import sys,json; m=json.load(open(sys.argv[1])); print(f'{m[\"sender\"]} says: {m[\"content\"]}')" "$msg_file")
            rm -f "$msg_file"
            run_claude "You received a message: $content. Respond appropriately based on your role." > /dev/null
        done <<< "$MESSAGES"
        # Update last seen timestamp after processing
        date -u +%Y-%m-%dT%H:%M:%SZ > "$LAST_SEEN_FILE"
    fi

    # Check kanban for work
    TASKS=$(check_kanban)
    if [ -n "$TASKS" ]; then
        echo "[vevria-agent] Found $(echo "$TASKS" | wc -l) assigned tasks..."
        while IFS= read -r task; do
            # Write task to temp file to safely extract fields without shell injection
            task_file=$(mktemp)
            printf '%s' "$task" > "$task_file"
            title=$(python3 -c "import sys,json; print(json.load(open(sys.argv[1]))['title'])" "$task_file")
            desc=$(python3 -c "import sys,json; print(json.load(open(sys.argv[1])).get('description',''))" "$task_file")
            rm -f "$task_file"
            echo "[vevria-agent] Working on: $title"
            run_claude "You have a task assigned to you: '$title'. Description: $desc. Work on it and report your progress." > /dev/null

            # After processing a coding task, trigger deploy
            task_type=$(echo "$task" | python3 -c "import sys,json; print(json.load(sys.stdin).get('task_type',''))" 2>/dev/null)
            if [ "$task_type" = "feature" ] || [ "$task_type" = "bugfix" ]; then
                trigger_redeploy
                # Wait up to 3 minutes for deploy, check every 30s
                for i in $(seq 1 6); do
                    sleep 30
                    status=$(check_deploy_status)
                    if [ "$status" = "running" ]; then
                        callback "Deploy complete — app is live" 0 0 0
                        break
                    elif [ "$status" = "failed" ]; then
                        callback "Deploy failed. I'll check the logs and try to fix." 0 0 0
                        break
                    fi
                done
            fi
        done <<< "$TASKS"
    fi

    echo "[vevria-agent] Cycle complete. Sleeping ${POLL_INTERVAL}s..."
done
