defmodule RagExCore.Code.GenericChunker do
  @moduledoc """
  Chunks generic code files into semantic units.
  """

  def chunk(path, content) do
    # Simple chunking strategy for generic files
    # Split by lines, creating chunks of reasonable size
    lines = String.split(content, "\n")
    chunk_size = 50  # lines per chunk

    lines
    |> Enum.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Enum.map(fn {chunk_lines, index} ->
      symbol = case Path.extname(path) do
        ".ex" -> "elixir_chunk_#{index}"
        ".js" -> "javascript_chunk_#{index}"
        ".py" -> "python_chunk_#{index}"
        ".rb" -> "ruby_chunk_#{index}"
        ".go" -> "go_chunk_#{index}"
        ".rs" -> "rust_chunk_#{index}"
        ".java" -> "java_chunk_#{index}"
        ".c" -> "c_chunk_#{index}"
        ".cpp" -> "cpp_chunk_#{index}"
        ".h" -> "header_chunk_#{index}"
        ".hpp" -> "hpp_chunk_#{index}"
        _ -> "generic_chunk_#{index}"
      end

      %{sym: symbol, body: Enum.join(chunk_lines, "\n")}
    end)
  end
end
