# Contributing

We welcome contributions to RagEx! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites

- Elixir 1.16+ and Erlang/OTP 27+
- Git
- SQLite3 development libraries
- Basic understanding of Elixir/OTP

### Development Setup

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/your-username/rag_ex.git
   cd rag_ex
   ```

2. **Install dependencies**:
   ```bash
   mix deps.get
   ```

3. **Set up the database**:
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

4. **Run tests**:
   ```bash
   mix test
   ```

5. **Start development server**:
   ```bash
   iex -S mix
   ```

## Development Workflow

### Branch Naming

Use descriptive branch names:
- `feature/add-new-embedding-model`
- `fix/sqlite-connection-issue`
- `docs/update-api-documentation`
- `refactor/optimize-vector-search`

### Commit Messages

Follow conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(api): add rate limiting to search endpoints

fix(db): resolve SQLite connection pool exhaustion

docs(readme): add installation instructions for macOS
```

### Pull Request Process

1. **Create a feature branch** from `main`
2. **Make your changes** with appropriate tests
3. **Update documentation** if needed
4. **Run the test suite** and ensure all tests pass
5. **Create a pull request** with a clear description

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

## Code Style Guidelines

### Elixir Style

Follow the official Elixir style guide:

```elixir
# Good
defmodule MyModule do
  @moduledoc "Module documentation"
  
  @doc "Function documentation"
  def my_function(param1, param2) do
    # Implementation
  end
end

# Bad
defmodule MyModule do
def my_function(param1,param2) do
# Implementation
end
end
```

### Documentation

- **Module documentation**: Use `@moduledoc` for all public modules
- **Function documentation**: Use `@doc` for all public functions
- **Examples**: Include usage examples in documentation
- **Typespecs**: Add `@spec` for all public functions

### Testing

- **Test coverage**: Maintain >90% test coverage
- **Test naming**: Use descriptive test names
- **Test organization**: Group related tests in `describe` blocks
- **Mocking**: Use appropriate mocking for external dependencies

```elixir
# Good test example
describe "RagEx.Query.search/3" do
  test "returns search results for valid query" do
    # Arrange
    repo_id = "test_repo"
    query = "authentication"
    k = 5
    
    # Act
    results = RagEx.Query.search(repo_id, query, k)
    
    # Assert
    assert is_list(results)
    assert length(results) <= k
  end
end
```

## Areas for Contribution

### High Priority

- **Performance optimization**: Vector search algorithms, database queries
- **New embedding models**: Integration with different embedding services
- **Error handling**: Better error messages and recovery
- **Monitoring**: Metrics, logging, and observability

### Medium Priority

- **New file formats**: Support for additional programming languages
- **API enhancements**: Additional endpoints and features
- **Documentation**: Examples, tutorials, and guides
- **Testing**: More comprehensive test coverage

### Low Priority

- **UI improvements**: Better CLI output and formatting
- **Configuration**: Additional configuration options
- **Docker**: Containerization improvements
- **CI/CD**: GitHub Actions and deployment automation

## Architecture Guidelines

### Module Organization

```
lib/rag_ex/
├── application.ex          # OTP application
├── repo.ex                 # Database repository
├── http.ex                 # HTTP server supervisor
├── router.ex               # HTTP routes
├── watcher.ex              # File system watcher
├── ingest.ex               # Code ingestion
├── query.ex                # Search and context
├── cli.ex                  # Command line interface
├── emb_bin.ex              # Embedding serialization
└── store/
    └── sqlite.ex           # Database operations
```

### Error Handling

```elixir
# Good error handling
def search(repo_id, query, k) do
  case validate_params(repo_id, query, k) do
    {:ok, params} -> perform_search(params)
    {:error, reason} -> {:error, reason}
  end
end

# Bad error handling
def search(repo_id, query, k) do
  perform_search(repo_id, query, k)  # No validation
end
```

### Performance Considerations

- **Database queries**: Use proper indexing and query optimization
- **Memory usage**: Be mindful of large datasets and embeddings
- **Concurrency**: Use appropriate supervision strategies
- **Resource cleanup**: Properly clean up resources and connections

## Testing Guidelines

### Unit Tests

Test individual functions and modules in isolation:

```elixir
defmodule RagEx.EmbBinTest do
  use ExUnit.Case, async: true
  
  describe "dump/1" do
    test "serializes float list to binary" do
      input = [0.1, 0.2, 0.3]
      result = RagEx.EmbBin.dump(input)
      
      assert is_binary(result)
      assert byte_size(result) == 12  # 3 floats * 4 bytes
    end
  end
end
```

### Integration Tests

Test component interactions:

```elixir
defmodule RagEx.IntegrationTest do
  use ExUnit.Case, async: false
  
  setup do
    # Setup test database
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(RagEx.Repo)
    :ok
  end
  
  test "full ingestion and search workflow" do
    # Test complete workflow
  end
end
```

### Property-Based Testing

Use ExCheck for property-based testing:

```elixir
defmodule RagEx.PropertyTest do
  use ExCheck
  
  property "embedding serialization is reversible" do
    forall embedding <- list(float()) do
      serialized = RagEx.EmbBin.dump(embedding)
      deserialized = RagEx.EmbBin.load(serialized)
      
      deserialized == embedding
    end
  end
end
```

## Release Process

### Version Bumping

Follow semantic versioning:
- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.0.1): Bug fixes, backward compatible

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in mix.exs
- [ ] Release notes prepared
- [ ] Tag created and pushed

## Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow the golden rule

### Getting Help

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Discord**: Real-time chat and support
- **Email**: Direct contact for sensitive issues

### Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation
- Annual contributor highlights

## License

By contributing to RagEx, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Questions?

If you have questions about contributing, please:

1. Check existing issues and discussions
2. Create a new issue with the "question" label
3. Join our Discord community
4. Contact the maintainers directly

Thank you for contributing to RagEx!
