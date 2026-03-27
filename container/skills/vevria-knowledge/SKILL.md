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
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge/search?q=search+terms"
```

### Get a specific document
```bash
curl -s -H "x-internal-key: $VEVRIA_INTERNAL_KEY" "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge/$DOC_ID"
```

### Create a document
```bash
curl -s -X POST -H "Content-Type: application/json" -H "x-internal-key: $VEVRIA_INTERNAL_KEY" \
  "$VEVRIA_API_URL/api/companies/$VEVRIA_COMPANY_ID/knowledge" \
  -d '{"title": "Document Title", "content": "Markdown content here", "doc_type": "document"}'
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

## Document types (`doc_type`)
`document`, `psi_output`, `research`, `spec`, `meeting_notes`

## Guidelines
- Use meaningful titles so documents are easy to find
- Write content in Markdown format
- Choose the correct `doc_type` for your document
- Search before creating to avoid duplicates
- Update existing documents rather than creating new versions
- Store important decisions with rationale so they can be referenced later
