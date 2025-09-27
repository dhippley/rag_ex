# AI Coding Assistant Integration

RagEx provides a local HTTP API that can be integrated with popular AI coding assistants to provide context-aware code suggestions and completions.

## Cursor Integration

Cursor can be configured to use RagEx as a custom context provider:

### 1. Create Cursor Configuration

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

### 2. Custom Cursor Extension

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

## VS Code Copilot Integration

### 1. VS Code Extension

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

### 2. Extension Implementation

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

## Windsurf Integration

### 1. Windsurf Configuration

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

### 2. Custom Windsurf Plugin

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

## Zed Integration

### 1. Zed Configuration

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

### 2. Zed Plugin

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

## Universal Integration Script

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

## Usage Examples

### For Cursor Users:
1. Start RagEx: `mix run --no-halt`
2. In Cursor, use `Ctrl+Shift+P` and search for "RagEx"
3. Or reference the API directly in your prompts

### For VS Code Users:
1. Install the RagEx extension
2. Use `Ctrl+Shift+R` to search code
3. Use `Ctrl+Shift+C` to get context

### For Windsurf Users:
1. Configure the context provider
2. RagEx will automatically enrich your prompts
3. Use the custom plugin for advanced features

### For Zed Users:
1. Configure the settings
2. Use the Lua plugin for context enrichment
3. RagEx will provide code context automatically

## Best Practices

1. **Start RagEx First**: Always ensure RagEx is running before using AI assistants
2. **Use Specific Queries**: More specific queries yield better results
3. **Adjust Token Budgets**: Tune the budget parameter based on your needs
4. **Monitor Performance**: Check RagEx logs for any issues
5. **Keep Data Fresh**: Regularly trigger ingestion to keep context up-to-date

## Troubleshooting

### Common Issues

**Connection Refused:**
```bash
# Check if RagEx is running
curl http://localhost:7788/health

# Start RagEx if not running
mix run --no-halt
```

**No Results Found:**
```bash
# Check if data has been ingested
curl "http://localhost:7788/v1/search?query=test&k=1"

# Trigger manual ingestion
curl -X POST http://localhost:7788/v1/ingest
```

**Slow Responses:**
- Check database size and indexing
- Monitor system resources
- Consider adjusting token budgets
- Review query specificity

### Debug Mode

Enable debug logging for integration troubleshooting:

```elixir
# config/dev.exs
config :logger, level: :debug
config :rag_ex, RagEx.Repo, log: :debug
```
