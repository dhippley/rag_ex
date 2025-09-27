# RagEx

[![Elixir CI](https://github.com/your-org/rag_ex/actions/workflows/elixir.yml/badge.svg)](https://github.com/your-org/rag_ex/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/rag_ex.svg)](https://hex.pm/packages/rag_ex)
[![HexDocs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/rag_ex/)

**A production-ready RAG (Retrieval-Augmented Generation) daemon for Elixir applications**

RagEx is a standalone OTP application that watches your codebase, ingests code chunks with embeddings, and exposes a local HTTP API for coding agents. Built with Elixir's fault-tolerant supervision trees and designed for high-performance vector similarity search.

## Features

- **Real-time Code Ingestion**: Automatically watches file system changes and ingests code chunks
- **Vector Similarity Search**: High-performance cosine similarity search using Nx tensors
- **MMR Algorithm**: Maximal Marginal Relevance for diverse, non-redundant context selection
- **Token Budget Management**: Intelligent context packing within specified token limits
- **HTTP API**: RESTful endpoints for search, context retrieval, and ingestion control
- **SQLite Storage**: Efficient local storage with proper indexing and WAL mode
- **Production Ready**: Built with OTP supervision trees, proper error handling, and graceful degradation

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Architecture](#architecture)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Installation

### Prerequisites

- Elixir 1.16+ and Erlang/OTP 27+
- SQLite3 development libraries
- Git (for cloning)

### From Source

```bash
git clone https://github.com/your-org/rag_ex.git
cd rag_ex
mix deps.get
mix compile
```

### As a Dependency

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:rag_ex, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Database Setup

```bash
# Create and migrate the database
mix ecto.create
mix ecto.migrate
```

### 2. Start the Daemon

```bash
# Start with default settings
mix run --no-halt

# Or run as a release
mix release
_build/prod/rel/rag_ex/bin/rag_ex start
```

### 3. Test the API

```bash
# Health check
curl http://localhost:7788/health

# Search for code
curl "http://localhost:7788/v1/search?query=function%20definition&k=5"

# Get context for coding
curl "http://localhost:7788/v1/context?query=authentication&budget=2000"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RAG_EX_PORT` | `7788` | HTTP server port |
| `RAG_EX_ROOT` | Current directory | Root directory to watch |
| `RAG_EX_REPO_ID` | Directory name | Repository identifier |

### Application Configuration

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

### Production Configuration

For production deployments, use environment-specific configs:

```elixir
# config/prod.exs
import Config

config :rag_ex,
  port: 8080,
  root: "/var/lib/rag_ex/repos/my-project",
  repo_id: "my-project"

config :rag_ex, RagEx.Repo,
  database: "/var/lib/rag_ex/data/production.sqlite3",
  pool_size: 20
```

## AI Coding Assistant Integration

RagEx provides a local HTTP API that can be integrated with popular AI coding assistants to provide context-aware code suggestions and completions.

### Cursor Integration

Cursor can be configured to use RagEx as a custom context provider:

#### 1. Create Cursor Configuration

Create `.cursorrules` in your project root:

```markdown
# Cursor Rules for RagEx Integration

## Context Provider
Use the local RagEx API at http://localhost:7788 for code context:

- Search: GET /v1/search?query={query}&k=10
- Context: GET /v1/context?query={query}&budget=3000

## Usage
When working on code, use RagEx to:
1. Search for related functions and modules
2. Get context about how similar patterns are implemented
3. Understand the codebase structure and relationships

## API Examples
```bash
# Search for authentication-related code
curl "http://localhost:7788/v1/search?query=authentication&k=5"

# Get context for user management
curl "http://localhost:7788/v1/context?query=user%20management&budget=2000"
```
```

#### 2. Custom Cursor Extension

Create a simple script to integrate with Cursor's context system:

```javascript
// scripts/cursor-rag-integration.js
const fetch = require('node-fetch');

class RagExContextProvider {
  constructor(baseUrl = 'http://localhost:7788') {
    this.baseUrl = baseUrl;
  }

  async searchCode(query, limit = 10) {
    const response = await fetch(`${this.baseUrl}/v1/search?query=${encodeURIComponent(query)}&k=${limit}`);
    return await response.json();
  }

  async getContext(query, budget = 3000) {
    const response = await fetch(`${this.baseUrl}/v1/context?query=${encodeURIComponent(query)}&budget=${budget}`);
    return await response.json();
  }
}

module.exports = RagExContextProvider;
```

### VS Code Copilot Integration

#### 1. VS Code Extension

Create a VS Code extension to integrate with RagEx:

```json
// package.json
{
  "name": "rag-ex-copilot",
  "displayName": "RagEx Copilot Integration",
  "description": "Integrates RagEx with VS Code Copilot",
  "version": "0.1.0",
  "engines": {
    "vscode": "^1.74.0"
  },
  "categories": ["Other"],
  "activationEvents": ["onCommand:ragEx.searchCode"],
  "main": "./out/extension.js",
  "contributes": {
    "commands": [
      {
        "command": "ragEx.searchCode",
        "title": "Search Code with RagEx"
      },
      {
        "command": "ragEx.getContext",
        "title": "Get Context with RagEx"
      }
    ],
    "keybindings": [
      {
        "command": "ragEx.searchCode",
        "key": "ctrl+shift+r",
        "mac": "cmd+shift+r"
      }
    ]
  }
}
```

#### 2. Extension Implementation

```typescript
// src/extension.ts
import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    const ragExProvider = new RagExProvider();
    
    const searchCommand = vscode.commands.registerCommand('ragEx.searchCode', async () => {
        const query = await vscode.window.showInputBox({
            prompt: 'Enter search query for RagEx',
            placeHolder: 'e.g., authentication, user management'
        });
        
        if (query) {
            const results = await ragExProvider.searchCode(query);
            const items = results.results.map((result: any) => ({
                label: `${result.sym} (${result.path})`,
                description: result.preview,
                detail: result.path
            }));
            
            const selected = await vscode.window.showQuickPick(items);
            if (selected) {
                const doc = await vscode.workspace.openTextDocument(selected.detail);
                await vscode.window.showTextDocument(doc);
            }
        }
    });
    
    context.subscriptions.push(searchCommand);
}

class RagExProvider {
    private baseUrl = 'http://localhost:7788';
    
    async searchCode(query: string, limit = 10) {
        const response = await fetch(`${this.baseUrl}/v1/search?query=${encodeURIComponent(query)}&k=${limit}`);
        return await response.json();
    }
    
    async getContext(query: string, budget = 3000) {
        const response = await fetch(`${this.baseUrl}/v1/context?query=${encodeURIComponent(query)}&budget=${budget}`);
        return await response.json();
    }
}
```

### Windsurf Integration

#### 1. Windsurf Configuration

Create `windsurf.config.json`:

```json
{
  "contextProviders": [
    {
      "name": "RagEx",
      "type": "http",
      "config": {
        "baseUrl": "http://localhost:7788",
        "endpoints": {
          "search": "/v1/search",
          "context": "/v1/context"
        }
      }
    }
  ],
  "rules": [
    "Use RagEx to search for related code patterns before suggesting implementations",
    "When asked about code structure, query RagEx for context about similar modules",
    "Always provide file paths and function names from RagEx results"
  ]
}
```

#### 2. Custom Windsurf Plugin

```javascript
// plugins/rag-ex-plugin.js
class RagExPlugin {
  constructor() {
    this.baseUrl = 'http://localhost:7788';
  }

  async searchCode(query, options = {}) {
    const { k = 10 } = options;
    const response = await fetch(`${this.baseUrl}/v1/search?query=${encodeURIComponent(query)}&k=${k}`);
    return await response.json();
  }

  async getContext(query, options = {}) {
    const { budget = 3000 } = options;
    const response = await fetch(`${this.baseUrl}/v1/context?query=${encodeURIComponent(query)}&budget=${budget}`);
    return await response.json();
  }

  async enrichPrompt(prompt) {
    // Extract key terms from the prompt
    const keywords = this.extractKeywords(prompt);
    
    // Search for relevant code
    const searchResults = await this.searchCode(keywords.join(' '), 5);
    
    // Get context
    const context = await this.getContext(prompt, 2000);
    
    return {
      originalPrompt: prompt,
      context: context.context,
      relevantFiles: searchResults.results.map(r => r.path),
      enrichedPrompt: `${prompt}\n\nRelevant code context:\n${context.context}`
    };
  }

  extractKeywords(text) {
    // Simple keyword extraction - you can make this more sophisticated
    return text.toLowerCase()
      .match(/\b\w{4,}\b/g) || [];
  }
}

module.exports = RagExPlugin;
```

### Zed Integration

#### 1. Zed Configuration

Create `.zed/settings.json`:

```json
{
  "ai": {
    "providers": {
      "rag_ex": {
        "type": "custom",
        "base_url": "http://localhost:7788",
        "endpoints": {
          "search": "/v1/search",
          "context": "/v1/context"
        }
      }
    }
  },
  "languages": {
    "elixir": {
      "ai": {
        "context_provider": "rag_ex"
      }
    }
  }
}
```

#### 2. Zed Plugin

Create `plugins/rag_ex.lua`:

```lua
-- RagEx integration for Zed
local M = {}

M.base_url = "http://localhost:7788"

function M.search_code(query, limit)
  limit = limit or 10
  local url = M.base_url .. "/v1/search?query=" .. query .. "&k=" .. limit
  
  local handle = io.popen("curl -s '" .. url .. "'")
  local result = handle:read("*a")
  handle:close()
  
  return vim.json.decode(result)
end

function M.get_context(query, budget)
  budget = budget or 3000
  local url = M.base_url .. "/v1/context?query=" .. query .. "&budget=" .. budget
  
  local handle = io.popen("curl -s '" .. url .. "'")
  local result = handle:read("*a")
  handle:close()
  
  return vim.json.decode(result)
end

function M.enrich_context(prompt)
  local context = M.get_context(prompt, 2000)
  return prompt .. "\n\nCode context:\n" .. context.context
end

return M
```

### Universal Integration Script

For any editor that supports custom commands, create a universal integration script:

```bash
#!/bin/bash
# scripts/rag-ex-integration.sh

RAG_EX_URL="http://localhost:7788"
COMMAND="$1"
QUERY="$2"

case $COMMAND in
  "search")
    curl -s "${RAG_EX_URL}/v1/search?query=${QUERY}&k=10" | jq '.results[] | {path: .path, symbol: .sym, preview: .preview}'
    ;;
  "context")
    curl -s "${RAG_EX_URL}/v1/context?query=${QUERY}&budget=3000" | jq '.context'
    ;;
  "health")
    curl -s "${RAG_EX_URL}/health"
    ;;
  *)
    echo "Usage: $0 {search|context|health} [query]"
    echo "Examples:"
    echo "  $0 search 'authentication'"
    echo "  $0 context 'user management'"
    echo "  $0 health"
    exit 1
    ;;
esac
```

### Usage Examples

#### For Cursor Users:
1. Start RagEx: `mix run --no-halt`
2. In Cursor, use `Ctrl+Shift+P` and search for "RagEx"
3. Or reference the API directly in your prompts

#### For VS Code Users:
1. Install the RagEx extension
2. Use `Ctrl+Shift+R` to search code
3. Use `Ctrl+Shift+C` to get context

#### For Windsurf Users:
1. Configure the context provider
2. RagEx will automatically enrich your prompts
3. Use the custom plugin for advanced features

#### For Zed Users:
1. Configure the settings
2. Use the Lua plugin for context enrichment
3. RagEx will provide code context automatically

### Best Practices

1. **Start RagEx First**: Always ensure RagEx is running before using AI assistants
2. **Use Specific Queries**: More specific queries yield better results
3. **Adjust Token Budgets**: Tune the budget parameter based on your needs
4. **Monitor Performance**: Check RagEx logs for any issues
5. **Keep Data Fresh**: Regularly trigger ingestion to keep context up-to-date

## API Reference

### Health Check

```http
GET /health
```

**Response:**
```json
{"ok": true}
```

### Search

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

### Context Retrieval

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

### Manual Ingestion

```http
POST /v1/ingest
```

**Response:**
```json
{"status": "queued"}
```

## Architecture

### Core Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   FileSystem    │───▶│   Ingestor      │───▶│   SQLite DB     │
│   Watcher       │    │   (Chunking +   │    │   (Embeddings)  │
│                 │    │    Embeddings)  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP API      │◀───│   Query Engine  │◀───│   Vector Search │
│   (REST)        │    │   (MMR + Pack)  │    │   (Cosine Sim)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Data Flow

1. **File System Monitoring**: Watches for file changes with debounced updates
2. **Code Chunking**: Breaks files into semantic chunks (modules, functions, etc.)
3. **Embedding Generation**: Creates vector embeddings for each chunk
4. **Storage**: Stores chunks and embeddings in SQLite with proper indexing
5. **Query Processing**: Vector similarity search with MMR for diverse results
6. **Context Packing**: Intelligent selection within token budgets

### Database Schema

```sql
CREATE TABLE code_chunks (
  id INTEGER PRIMARY KEY,
  repo_id TEXT NOT NULL,
  path TEXT NOT NULL,
  chunk_ix INTEGER NOT NULL,
  lang TEXT NOT NULL,
  sym TEXT NOT NULL,
  text TEXT NOT NULL,
  embedding BLOB,
  sha TEXT NOT NULL,
  tok_count INTEGER DEFAULT 0,
  meta JSON DEFAULT '{}',
  inserted_at DATETIME,
  updated_at DATETIME,
  UNIQUE(repo_id, path, chunk_ix)
);

CREATE INDEX idx_code_chunks_repo_path ON code_chunks(repo_id, path);
```

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test
mix test test/rag_ex_test.exs:30
```

### Development Server

```bash
# Start with auto-reload
iex -S mix

# Start daemon in development
mix run --no-halt
```

### Building Releases

```bash
# Build release
mix release

# Run release
_build/prod/rel/rag_ex/bin/rag_ex start

# Run with custom config
_build/prod/rel/rag_ex/bin/rag_ex start --root /path/to/repo --port 8080
```

### CLI Options

```bash
# One-time ingestion
mix run -e "RagEx.CLI.main([\"--once\"])"

# Custom root directory
mix run -e "RagEx.CLI.main([\"--root\", \"/path/to/repo\"])"

# Custom port
mix run -e "RagEx.CLI.main([\"--port\", \"8080\"])"
```

## Performance Tuning

### Database Optimization

```elixir
# config/prod.exs
config :rag_ex, RagEx.Repo,
  database: "/var/lib/rag_ex/data/production.sqlite3",
  pool_size: 20,
  timeout: 30_000,
  queue_target: 5_000,
  queue_interval: 1_000
```

### Memory Management

```elixir
# config/prod.exs
config :rag_ex,
  # Adjust based on your embedding model
  embedding_dimensions: 384,
  # Batch size for embedding generation
  embedding_batch_size: 10,
  # Maximum chunks to process per ingestion
  max_chunks_per_ingestion: 1000
```

### Monitoring

```elixir
# Add to your supervision tree
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ... other children
      RagEx.Application,
      # Add monitoring
      {TelemetryUI, port: 4001}
    ]
    
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

## Troubleshooting

### Common Issues

**Database locked errors:**
```bash
# Check for running processes
ps aux | grep rag_ex

# Kill stuck processes
pkill -f rag_ex

# Reset database
rm data/rag_ex.sqlite3*
mix ecto.create
mix ecto.migrate
```

**Port already in use:**
```bash
# Find process using port
lsof -i :7788

# Kill process
kill -9 <PID>

# Or use different port
mix run --no-halt -e "Application.put_env(:rag_ex, :port, 8080)"
```

**File watcher not working:**
- On macOS: Install `fswatch` or use polling mode
- On Linux: Ensure inotify limits are sufficient
- Check file permissions on watched directories

### Debug Mode

```elixir
# Enable debug logging
config :logger, level: :debug

# Enable Ecto query logging
config :rag_ex, RagEx.Repo, log: :debug
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Run the test suite: `mix test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Development Setup

```bash
# Clone and setup
git clone https://github.com/your-org/rag_ex.git
cd rag_ex
mix deps.get
mix ecto.create
mix ecto.migrate

# Run tests
mix test

# Start development server
iex -S mix
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Elixir](https://elixir-lang.org/) and [OTP](https://www.erlang.org/doc/design_principles/des_princ.html)
- Vector operations powered by [Nx](https://github.com/elixir-nx/nx)
- Database layer provided by [Ecto](https://hexdocs.pm/ecto/Ecto.html)
- HTTP server built with [Plug.Cowboy](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html)

---

**Made with love by the RagEx team**