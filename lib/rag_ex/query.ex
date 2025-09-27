defmodule RagEx.Query do
  alias RagExCore.{Embeddings, Code.Pack}
  alias RagEx.Store.SQLite

  def context(repo, query, budget) do
    {:ok, qvec} = Embeddings.embed(query)
    chunks = SQLite.nearest(repo, qvec, 60)
    selected = mmr(qvec, chunks, 12)
    Pack.pack(selected, budget)
  end

  def search(repo, query, k) do
    {:ok, qvec} = Embeddings.embed(query)
    SQLite.nearest(repo, qvec, k)
    |> Enum.map(&%{path: &1.path, sym: &1.sym, chunk_ix: &1.chunk_ix, preview: String.slice(&1.text, 0, 200)})
  end

  defp mmr(qvec, candidates, k) do
    import Nx, only: [tensor: 1, to_number: 1, sum: 1, sqrt: 1, multiply: 2, divide: 2]
    q = tensor(qvec)
    norm = fn x -> divide(x, Nx.max(sqrt(sum(multiply(x, x))), 1.0e-9)) end
    q = norm.(q)
    take = []
    # Ensure we're only passing the embedding list to tensor/1
    vmap = for c <- candidates, into: %{} do
      embedding_list = Map.get(c, :embedding)
      # Add safety check to ensure we have a list
      if is_list(embedding_list) do
        {c, norm.(tensor(embedding_list))}
      else
        raise "Expected embedding to be a list, got: #{inspect(embedding_list)}"
      end
    end
    loop_mmr(q, candidates, take, vmap, k)
  end

  defp loop_mmr(_q, _cand, take, _vmap, k) when length(take) >= k, do: take
  defp loop_mmr(_q, [], take, _vmap, _k), do: take
  defp loop_mmr(q, cand, take, vmap, k) do
    import Nx, only: [to_number: 1, sum: 1, multiply: 2]
    cos = fn a, b -> to_number(sum(multiply(a, b))) end
    next =
      cand
      |> Enum.max_by(fn c ->
        r = cos.(q, vmap[c])
        d = case take do
          [] -> 0.0
          _ -> take |> Enum.map(&cos.(vmap[&1], vmap[c])) |> Enum.max(fn -> 0.0 end)
        end
        0.6*r - 0.4*d
      end)
    loop_mmr(q, Enum.reject(cand, &(&1==next)), [next|take], vmap, k)
  end
end
