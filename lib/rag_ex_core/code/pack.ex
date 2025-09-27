defmodule RagExCore.Code.Pack do
  @moduledoc """
  Packs chunks into a context with token budget constraints.
  """

  def pack(chunks, budget) do
    # Simple packing strategy - take chunks until we hit the token budget
    {packed, _current_tokens} =
      Enum.reduce_while(chunks, {[], 0}, fn chunk, {packed, current_tokens} ->
        chunk_tokens = estimate_tokens(chunk.text)
        if current_tokens + chunk_tokens <= budget do
          {:cont, {[chunk | packed], current_tokens + chunk_tokens}}
        else
          {:halt, {packed, current_tokens}}
        end
      end)

    packed
    |> Enum.reverse()
    |> Enum.map(& &1.text)
    |> Enum.join("\n\n---\n\n")
  end

  defp estimate_tokens(text) do
    # Rough token estimation - 4 characters per token
    div(String.length(text), 4)
  end
end
