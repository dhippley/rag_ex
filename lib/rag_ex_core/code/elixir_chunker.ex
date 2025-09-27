defmodule RagExCore.Code.ElixirChunker do
  @moduledoc """
  Chunks Elixir code files into semantic units.
  """

  def chunk(_path, content) do
    # Simple chunking strategy for Elixir files
    # Split by module definitions, function definitions, etc.
    lines = String.split(content, "\n")
    initial_chunks = []

    {final_chunks, current_chunk, current_symbol} =
      Enum.reduce(lines, {initial_chunks, [], "file"}, fn line, {chunks, current_chunk, current_symbol} ->
        trimmed = String.trim(line)

        cond do
          # Module definition
          String.starts_with?(trimmed, "defmodule ") ->
            new_chunks = if current_chunk != [] do
              [%{sym: current_symbol, body: Enum.join(current_chunk, "\n")} | chunks]
            else
              chunks
            end
            new_current_chunk = [line]
            new_current_symbol = extract_module_name(trimmed)
            {new_chunks, new_current_chunk, new_current_symbol}

          # Function definition
          String.starts_with?(trimmed, "def ") or String.starts_with?(trimmed, "defp ") ->
            new_chunks = if current_chunk != [] do
              [%{sym: current_symbol, body: Enum.join(current_chunk, "\n")} | chunks]
            else
              chunks
            end
            new_current_chunk = [line]
            new_current_symbol = extract_function_name(trimmed)
            {new_chunks, new_current_chunk, new_current_symbol}

          # Test definition
          String.starts_with?(trimmed, "test ") ->
            new_chunks = if current_chunk != [] do
              [%{sym: current_symbol, body: Enum.join(current_chunk, "\n")} | chunks]
            else
              chunks
            end
            new_current_chunk = [line]
            new_current_symbol = "test"
            {new_chunks, new_current_chunk, new_current_symbol}

          # Other lines
          true ->
            new_current_chunk = [line | current_chunk]
            {chunks, new_current_chunk, current_symbol}
        end
      end)

    # Add the last chunk
    final_chunks = if current_chunk != [] do
      [%{sym: current_symbol, body: Enum.join(Enum.reverse(current_chunk), "\n")} | final_chunks]
    else
      final_chunks
    end

    Enum.reverse(final_chunks)
  end

  defp extract_module_name(line) do
    case Regex.run(~r/defmodule\s+([A-Za-z0-9._]+)/, line) do
      [_, name] -> name
      _ -> "module"
    end
  end

  defp extract_function_name(line) do
    case Regex.run(~r/defp?\s+([a-zA-Z_][a-zA-Z0-9_]*)/, line) do
      [_, name] -> name
      _ -> "function"
    end
  end
end
