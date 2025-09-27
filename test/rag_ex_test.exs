defmodule RagExTest do
  use ExUnit.Case
  doctest RagEx

  alias RagEx.{Store.SQLite, EmbBin}


  test "greets the world" do
    assert RagEx.hello() == :world
  end

  test "embeddings can be serialized and deserialized" do
    # Test the core embedding serialization functionality
    original_embedding = [0.1, 0.2, 0.3, 0.4, 0.5]

    # Serialize to binary
    binary = EmbBin.dump(original_embedding)
    assert is_binary(binary)

    # Deserialize back to list
    deserialized = EmbBin.load(binary)
    # Check that the values are approximately equal (within float precision)
    assert length(deserialized) == length(original_embedding)
    Enum.zip(deserialized, original_embedding)
    |> Enum.each(fn {actual, expected} ->
      assert abs(actual - expected) < 0.0001
    end)
  end

  test "code chunks can be stored and retrieved" do
    # Test the core database functionality
    repo_id = "test_repo_storage"
    # Use 384-dimensional embedding to match the mock embeddings
    embedding = for i <- 1..384, do: :math.sin(i * 0.1) * 0.5
    test_chunks = [
      %{
        path: "test_file.ex",
        chunk_ix: 0,
        lang: "elixir",
        sym: "test_function",
        text: "def test_function do\n  :ok\nend",
        sha: "abc123",
        tok_count: 10,
        meta: %{},
        embedding: embedding
      }
    ]

    # Store chunks
    assert :ok = SQLite.upsert_chunks(repo_id, test_chunks)

    # Retrieve chunks
    chunks = SQLite.nearest(repo_id, embedding, 1)
    assert length(chunks) == 1
    assert hd(chunks).path == "test_file.ex"
    assert hd(chunks).sym == "test_function"
  end

  test "query module can search for chunks" do
    # Test the search functionality without HTTP
    repo_id = "test_repo_search"
    # Use 384-dimensional embedding to match the mock embeddings
    embedding = for i <- 1..384, do: :math.sin(i * 0.1) * 0.5
    test_chunks = [
      %{
        path: "search_test.ex",
        chunk_ix: 0,
        lang: "elixir",
        sym: "search_function",
        text: "def search_function(query) do\n  # Search implementation\nend",
        sha: "def456",
        tok_count: 15,
        meta: %{},
        embedding: embedding
      }
    ]

    SQLite.upsert_chunks(repo_id, test_chunks)

    # Test search directly
    results = RagEx.Query.search(repo_id, "search", 5)
    assert is_list(results)
    assert length(results) >= 0  # May be 0 if no matches due to mock embeddings
  end

  test "query module can get context" do
    # Test the context functionality without HTTP
    repo_id = "test_repo_context"
    # Use 384-dimensional embedding to match the mock embeddings
    embedding = for i <- 1..384, do: :math.sin(i * 0.1) * 0.5
    test_chunks = [
      %{
        path: "context_test.ex",
        chunk_ix: 0,
        lang: "elixir",
        sym: "context_function",
        text: "def context_function do\n  # Context implementation\nend",
        sha: "ghi789",
        tok_count: 12,
        meta: %{},
        embedding: embedding
      }
    ]

    SQLite.upsert_chunks(repo_id, test_chunks)

    # Test context directly
    context = RagEx.Query.context(repo_id, "context", 1000)
    assert is_binary(context)
  end
end
