defmodule RagEx.EmbBin do
  @doc "Serialize list of floats to binary (float32 little-endian)."
  def dump(list) when is_list(list) do
    for f <- list, into: <<>>, do: <<f::float-32-little>>
  end

  @doc "Deserialize binary to list of floats."
  def load(<<>>), do: []
  def load(bin) when is_binary(bin) do
    for <<x::float-32-little <- bin>>, do: x
  end
end
