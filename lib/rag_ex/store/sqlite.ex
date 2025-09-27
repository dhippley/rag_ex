defmodule RagEx.Store.SQLite do
  use Ecto.Schema
  import Ecto.Query
  alias RagEx.{Repo}
  alias RagEx.EmbBin

  schema "code_chunks" do
    field :repo_id, :string
    field :path, :string
    field :chunk_ix, :integer
    field :lang, :string
    field :sym, :string
    field :text, :string
    field :embedding, :binary
    field :sha, :string
    field :tok_count, :integer
    field :meta, :map
    timestamps()
  end

  def upsert_chunks(repo_id, entries) do
    Repo.transaction(fn ->
      Enum.each(entries, fn e ->
        attrs = Map.merge(e, %{repo_id: repo_id, embedding: EmbBin.dump(e.embedding)})
        q = from c in __MODULE__, where: c.repo_id == ^repo_id and c.path == ^e.path and c.chunk_ix == ^e.chunk_ix
        case Repo.one(q) do
          nil -> Repo.insert!(struct(__MODULE__, attrs))
          rec -> Repo.update!(Ecto.Changeset.change(rec, Map.delete(attrs, :repo_id)))
        end
      end)
    end)
    :ok
  end

  def nearest(repo_id, qvec, k) do
    import Nx, only: [tensor: 1, to_number: 1, sum: 1, sqrt: 1, multiply: 2, divide: 2]
    q = tensor(qvec)
    qn = divide(q, Nx.max(sqrt(sum(multiply(q, q))), 1.0e-9))

    from(c in __MODULE__, where: c.repo_id == ^repo_id, select: %{id: c.id, path: c.path, chunk_ix: c.chunk_ix, lang: c.lang, sym: c.sym, text: c.text, embedding: c.embedding})
    |> Repo.all()
    |> Enum.map(fn row ->
      v = row.embedding |> EmbBin.load()
      vn = tensor(v)
      vn = divide(vn, Nx.max(sqrt(sum(multiply(vn, vn))), 1.0e-9))
      score = to_number(sum(multiply(qn, vn)))
      {Map.put(row, :embedding, v), score}
    end)
    |> Enum.sort_by(fn {_r, s} -> -s end)
    |> Enum.take(k)
    |> Enum.map(&elem(&1, 0))
  end
end
