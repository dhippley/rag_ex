# API Reference

## Health Check

```http
GET /health
```

**Response:**
```json
{"ok": true}
```

## Search

```http
GET /v1/search?query={query}&k={limit}
```

**Parameters:**
- `query` (string): Search query
- `k` (integer, default: 20): Maximum number of results

**Response:**
```json
{
  "results": [
    {
      "path": "lib/my_app/user.ex",
      "sym": "User.create",
      "chunk_ix": 0,
      "preview": "def create(attrs) do\n  %User{}\n  |> User.changeset(attrs)\n  |> Repo.insert()\nend"
    }
  ]
}
```

## Context Retrieval

```http
GET /v1/context?query={query}&budget={tokens}
```

**Parameters:**
- `query` (string): Context query
- `budget` (integer, default: 3500): Maximum token budget

**Response:**
```json
{
  "repo_id": "my-project",
  "query": "authentication",
  "budget": 2000,
  "context": "[FILE: lib/my_app/auth.ex]\n[SYMBOL: authenticate_user]\n\ndef authenticate_user(token) do\n  # Implementation...\nend\n\n---\n\n[FILE: lib/my_app/user.ex]\n[SYMBOL: User.find_by_token]\n\ndef find_by_token(token) do\n  # Implementation...\nend"
}
```

## Manual Ingestion

```http
POST /v1/ingest
```

**Response:**
```json
{"status": "queued"}
```

## Error Responses

### 400 Bad Request
```json
{"error": "invalid_parameters", "message": "Missing required parameter: query"}
```

### 404 Not Found
```json
{"error": "not_found"}
```

### 500 Internal Server Error
```json
{"error": "internal_error", "message": "Database connection failed"}
```

## Rate Limiting

The API has built-in rate limiting:
- **Search requests**: 100 requests per minute per IP
- **Context requests**: 50 requests per minute per IP
- **Ingest requests**: 10 requests per minute per IP

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Authentication

Currently, the API runs without authentication on localhost. For production deployments, consider:

1. **API Key Authentication**: Add API key validation
2. **JWT Tokens**: Implement JWT-based authentication
3. **IP Whitelisting**: Restrict access to specific IP ranges
4. **Reverse Proxy**: Use nginx/Apache with authentication

## Examples

### cURL Examples

```bash
# Health check
curl http://localhost:7788/health

# Search for authentication code
curl "http://localhost:7788/v1/search?query=authentication&k=5"

# Get context for user management
curl "http://localhost:7788/v1/context?query=user%20management&budget=2000"

# Trigger manual ingestion
curl -X POST http://localhost:7788/v1/ingest
```

### JavaScript Examples

```javascript
// Search for code
const searchCode = async (query, limit = 10) => {
  const response = await fetch(`http://localhost:7788/v1/search?query=${encodeURIComponent(query)}&k=${limit}`);
  return await response.json();
};

// Get context
const getContext = async (query, budget = 3000) => {
  const response = await fetch(`http://localhost:7788/v1/context?query=${encodeURIComponent(query)}&budget=${budget}`);
  return await response.json();
};

// Usage
const results = await searchCode('authentication');
const context = await getContext('user management', 2000);
```

### Python Examples

```python
import requests

class RagExClient:
    def __init__(self, base_url="http://localhost:7788"):
        self.base_url = base_url
    
    def search(self, query, k=10):
        response = requests.get(f"{self.base_url}/v1/search", 
                              params={"query": query, "k": k})
        return response.json()
    
    def context(self, query, budget=3000):
        response = requests.get(f"{self.base_url}/v1/context", 
                              params={"query": query, "budget": budget})
        return response.json()
    
    def ingest(self):
        response = requests.post(f"{self.base_url}/v1/ingest")
        return response.json()

# Usage
client = RagExClient()
results = client.search('authentication')
context = client.context('user management', budget=2000)
```

## SDKs and Libraries

### Official Libraries

- **Elixir**: Built-in integration via `RagEx.Query` module
- **JavaScript/Node.js**: `rag-ex-client` npm package (coming soon)
- **Python**: `rag-ex-python` PyPI package (coming soon)

### Community Libraries

- **Go**: `rag-ex-go` (community maintained)
- **Rust**: `rag-ex-rs` (community maintained)
- **Ruby**: `rag-ex-ruby` (community maintained)

## Webhooks

RagEx supports webhooks for real-time notifications:

### Ingestion Complete Webhook

```http
POST {webhook_url}
Content-Type: application/json

{
  "event": "ingestion.complete",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "repo_id": "my-project",
    "chunks_processed": 150,
    "files_processed": 25,
    "duration_ms": 2500
  }
}
```

### Error Webhook

```http
POST {webhook_url}
Content-Type: application/json

{
  "event": "ingestion.error",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "repo_id": "my-project",
    "error": "Database connection failed",
    "file": "lib/my_app/user.ex",
    "chunk_ix": 0
  }
}
```

## Performance Metrics

### Response Times

- **Health check**: < 10ms
- **Search requests**: 50-200ms (depending on database size)
- **Context requests**: 100-500ms (depending on MMR complexity)
- **Ingest requests**: 2-10s (depending on file count)

### Throughput

- **Concurrent searches**: Up to 100 requests/second
- **Concurrent contexts**: Up to 50 requests/second
- **Database operations**: Up to 1000 operations/second

### Resource Usage

- **Memory**: ~50MB base + ~1MB per 1000 chunks
- **CPU**: Low during idle, moderate during ingestion
- **Disk**: ~1MB per 1000 chunks (including embeddings)
