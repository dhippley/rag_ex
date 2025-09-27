# Configuration

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RAG_EX_PORT` | `7788` | HTTP server port |
| `RAG_EX_ROOT` | Current directory | Root directory to watch |
| `RAG_EX_REPO_ID` | Directory name | Repository identifier |

## Application Configuration

Create `config/config.exs`:

```elixir
import Config

config :rag_ex,
  ecto_repos: [RagEx.Repo],
  port: System.get_env("RAG_EX_PORT", "7788") |> String.to_integer(),
  root: System.get_env("RAG_EX_ROOT", File.cwd!()),
  repo_id: System.get_env("RAG_EX_REPO_ID", Path.basename(File.cwd!()))

config :rag_ex, RagEx.Repo,
  database: Path.expand("data/rag_ex.sqlite3", File.cwd!()),
  pool_size: 5
```

## Environment-Specific Configuration

### Development

```elixir
# config/dev.exs
import Config

config :rag_ex,
  port: 4000,
  root: File.cwd!(),
  repo_id: "rag_ex_dev"

config :rag_ex, RagEx.Repo,
  database: Path.expand("data/dev.sqlite3", File.cwd!()),
  pool_size: 5,
  log: :debug
```

### Test

```elixir
# config/test.exs
import Config

config :rag_ex,
  port: 4001,
  root: File.cwd!(),
  repo_id: "rag_ex_test"

config :rag_ex, RagEx.Repo,
  database: Path.expand("data/test.sqlite3", File.cwd!()),
  pool_size: 1,
  log: false
```

### Production

```elixir
# config/prod.exs
import Config

config :rag_ex,
  port: 8080,
  root: "/var/lib/rag_ex/repos/my-project",
  repo_id: "my-project"

config :rag_ex, RagEx.Repo,
  database: "/var/lib/rag_ex/data/production.sqlite3",
  pool_size: 20,
  timeout: 30_000,
  queue_target: 5_000,
  queue_interval: 1_000
```

## Database Configuration

### SQLite Settings

```elixir
config :rag_ex, RagEx.Repo,
  database: "/path/to/database.sqlite3",
  pool_size: 20,
  timeout: 30_000,
  queue_target: 5_000,
  queue_interval: 1_000,
  # WAL mode settings
  journal_mode: "WAL",
  synchronous: "NORMAL",
  cache_size: -64_000,  # 64MB cache
  temp_store: "MEMORY"
```

### Connection Pooling

```elixir
config :rag_ex, RagEx.Repo,
  pool_size: 20,           # Number of connections
  timeout: 30_000,         # Connection timeout (ms)
  queue_target: 5_000,     # Queue target size
  queue_interval: 1_000    # Queue check interval (ms)
```

## File System Configuration

### Watched Directories

```elixir
config :rag_ex,
  # Single directory
  root: "/path/to/repo",
  
  # Multiple directories (if supported)
  watch_dirs: [
    "/path/to/repo1",
    "/path/to/repo2"
  ],
  
  # File patterns to include/exclude
  include_patterns: ["*.ex", "*.exs", "*.js", "*.ts"],
  exclude_patterns: ["**/node_modules/**", "**/deps/**", "**/_build/**"]
```

### File Filtering

```elixir
config :rag_ex,
  # File size limits
  max_file_size: 1_000_000,  # 1MB
  
  # File age limits
  min_file_age: 60,  # 60 seconds
  
  # Language-specific settings
  languages: %{
    "elixir" => %{
      enabled: true,
      chunk_size: 50,
      max_chunks: 1000
    },
    "javascript" => %{
      enabled: true,
      chunk_size: 100,
      max_chunks: 500
    }
  }
```

## HTTP Server Configuration

### Basic Settings

```elixir
config :rag_ex,
  port: 7788,
  host: "127.0.0.1",  # or "0.0.0.0" for all interfaces
  scheme: :http,      # or :https
  ssl: false
```

### HTTPS Configuration

```elixir
config :rag_ex,
  port: 443,
  scheme: :https,
  ssl: [
    keyfile: "/path/to/private.key",
    certfile: "/path/to/certificate.crt",
    cacertfile: "/path/to/ca.crt"
  ]
```

### CORS Configuration

```elixir
config :rag_ex,
  cors: [
    origins: ["http://localhost:3000", "https://myapp.com"],
    methods: ["GET", "POST"],
    headers: ["Content-Type", "Authorization"]
  ]
```

## Performance Configuration

### Memory Management

```elixir
config :rag_ex,
  # Embedding settings
  embedding_dimensions: 384,
  embedding_batch_size: 10,
  max_chunks_per_ingestion: 1000,
  
  # Cache settings
  cache_size: 1000,  # Number of items to cache
  cache_ttl: 3600,   # Cache TTL in seconds
  
  # Processing limits
  max_concurrent_ingestions: 3,
  ingestion_timeout: 300_000  # 5 minutes
```

### Database Optimization

```elixir
config :rag_ex, RagEx.Repo,
  # SQLite optimization
  journal_mode: "WAL",
  synchronous: "NORMAL",
  cache_size: -64_000,  # 64MB cache
  temp_store: "MEMORY",
  
  # Connection settings
  pool_size: 20,
  timeout: 30_000,
  queue_target: 5_000,
  queue_interval: 1_000
```

## Logging Configuration

### Log Levels

```elixir
config :logger,
  level: :info,  # :debug, :info, :warn, :error
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]
```

### Structured Logging

```elixir
config :logger,
  backends: [:console, :json],
  json: [
    level: :info,
    metadata: [:request_id, :user_id]
  ]
```

### Log Rotation

```elixir
config :logger,
  backends: [{LoggerFileBackend, :file}],
  file: [
    level: :info,
    path: "/var/log/rag_ex/application.log",
    max_bytes: 10_000_000,  # 10MB
    max_files: 5
  ]
```

## Security Configuration

### Authentication

```elixir
config :rag_ex,
  auth: [
    enabled: true,
    type: :api_key,  # :api_key, :jwt, :oauth
    api_key: "your-secret-api-key",
    jwt_secret: "your-jwt-secret"
  ]
```

### Rate Limiting

```elixir
config :rag_ex,
  rate_limit: [
    enabled: true,
    search: [requests: 100, window: 60],      # 100 req/min
    context: [requests: 50, window: 60],      # 50 req/min
    ingest: [requests: 10, window: 60]        # 10 req/min
  ]
```

### IP Whitelisting

```elixir
config :rag_ex,
  allowed_ips: [
    "127.0.0.1",
    "192.168.1.0/24",
    "10.0.0.0/8"
  ]
```

## Monitoring Configuration

### Metrics

```elixir
config :rag_ex,
  metrics: [
    enabled: true,
    port: 9090,
    path: "/metrics"
  ]
```

### Health Checks

```elixir
config :rag_ex,
  health_check: [
    enabled: true,
    interval: 30_000,  # 30 seconds
    timeout: 5_000     # 5 seconds
  ]
```

### Alerting

```elixir
config :rag_ex,
  alerts: [
    enabled: true,
    webhook_url: "https://hooks.slack.com/your-webhook",
    thresholds: %{
      error_rate: 0.05,      # 5% error rate
      response_time: 1000,   # 1 second
      memory_usage: 0.8      # 80% memory usage
    }
  ]
```

## Docker Configuration

### Dockerfile

```dockerfile
FROM elixir:1.16-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache sqlite

# Copy application files
COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .
RUN mix compile

# Create data directory
RUN mkdir -p /app/data

# Expose port
EXPOSE 7788

# Start application
CMD ["mix", "run", "--no-halt"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  rag_ex:
    build: .
    ports:
      - "7788:7788"
    volumes:
      - ./data:/app/data
      - ./repos:/app/repos
    environment:
      - RAG_EX_PORT=7788
      - RAG_EX_ROOT=/app/repos
      - RAG_EX_REPO_ID=my-project
    restart: unless-stopped
```

## Kubernetes Configuration

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rag-ex
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rag-ex
  template:
    metadata:
      labels:
        app: rag-ex
    spec:
      containers:
      - name: rag-ex
        image: rag-ex:latest
        ports:
        - containerPort: 7788
        env:
        - name: RAG_EX_PORT
          value: "7788"
        - name: RAG_EX_ROOT
          value: "/app/repos"
        - name: RAG_EX_REPO_ID
          value: "my-project"
        volumeMounts:
        - name: data
          mountPath: /app/data
        - name: repos
          mountPath: /app/repos
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: rag-ex-data
      - name: repos
        persistentVolumeClaim:
          claimName: rag-ex-repos
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rag-ex-service
spec:
  selector:
    app: rag-ex
  ports:
  - port: 7788
    targetPort: 7788
  type: LoadBalancer
```

## Environment-Specific Examples

### Local Development

```bash
# .env.local
RAG_EX_PORT=4000
RAG_EX_ROOT=/Users/developer/my-project
RAG_EX_REPO_ID=my-project-dev
```

### Staging

```bash
# .env.staging
RAG_EX_PORT=8080
RAG_EX_ROOT=/var/lib/rag_ex/repos/my-project
RAG_EX_REPO_ID=my-project-staging
```

### Production

```bash
# .env.production
RAG_EX_PORT=443
RAG_EX_ROOT=/var/lib/rag_ex/repos/my-project
RAG_EX_REPO_ID=my-project
RAG_EX_SSL_KEY=/etc/ssl/private/rag_ex.key
RAG_EX_SSL_CERT=/etc/ssl/certs/rag_ex.crt
```
