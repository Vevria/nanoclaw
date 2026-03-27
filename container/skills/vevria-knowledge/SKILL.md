---
name: vevria-knowledge
description: Access and manage the company's knowledge base — create, read, update, and delete documents. Use when storing or retrieving company information, decisions, and research.
---

# Knowledge Base Management

Store and retrieve company documents, decisions, research, and reference material.

## API Base URL
`$VEVRIA_API_URL` (set in environment)

## Authentication
Include header: `x-internal-key: $VEVRIA_INTERNAL_KEY`

## Endpoints

### List all documents
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge"
```

### Search documents
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge?q=search+terms"
```

### Get a specific document
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge/$DOC_ID"
```

### Create a document
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge" \
  -d '{"title": "Document Title", "content": "Markdown content here", "category": "research", "tags": ["tag1", "tag2"]}'
```

### Update a document
```bash
curl -s -X PUT -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge/$DOC_ID" \
  -d '{"title": "Updated Title", "content": "Updated content"}'
```

### Delete a document
```bash
curl -s -X DELETE -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge/$DOC_ID"
```

## Categories
`research`, `decision`, `architecture`, `meeting-notes`, `reference`, `strategy`

## Guidelines
- Use meaningful titles and categories so documents are easy to find
- Write content in Markdown format
- Tag documents for cross-referencing
- Search before creating to avoid duplicates
- Update existing documents rather than creating new versions
- Store important decisions with rationale so they can be referenced later
