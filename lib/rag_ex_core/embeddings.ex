defmodule RagExCore.Embeddings do
  @moduledoc """
  Mock embeddings module for testing purposes.
  In a real implementation, this would interface with an embedding service.
  """

  def embed(text) when is_binary(text) do
    # Mock embedding - return a random vector of 384 dimensions (typical for sentence transformers)
    # Generate simple values in range [-1.0, 1.0]
    embedding = for i <- 1..384, do: :math.sin(i * 0.1) * 0.5
    {:ok, embedding}
  end

  def embed_many(texts) when is_list(texts) do
    embeddings = Enum.map(texts, fn _text ->
      for i <- 1..384, do: :math.sin(i * 0.1) * 0.5
    end)
    {:ok, embeddings}
  end
end
