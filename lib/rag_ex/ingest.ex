defmodule RagEx.Ingest do
  alias RagExCore.{Embeddings, Code.ElixirChunker, Code.GenericChunker, Code.Walker}
  alias RagEx.Store.SQLite
  def enqueue, do: Task.start(fn -> run_once() end)

  def run_once do
    root = Application.get_env(:rag_ex, :root, File.cwd!())
    repo = Application.get_env(:rag_ex, :repo_id, Path.basename(root))
    files = Walker.list_files(root)

    entries =
      files
      |> Enum.flat_map(&chunk_file/1)

    {:ok, vecs} = entries |> Enum.map(& &1.text) |> Embeddings.embed_many()
    with_vecs = Enum.zip(entries, vecs) |> Enum.map(fn {e, v} -> Map.put(e, :embedding, v) end)
    SQLite.upsert_chunks(repo, with_vecs)
  end

  defp chunk_file(path) do
    content = File.read!(path)
    lang = case Path.extname(path) do ".ex"->:elixir; ".exs"->:elixir; ".heex"->:elixir; _->:generic end
    chunks =
      case lang do
        :elixir -> ElixirChunker.chunk(path, content)
        _ -> GenericChunker.chunk(path, content)
      end
    Enum.with_index(chunks)
    |> Enum.map(fn {c, ix} ->
      rel = Path.relative_to_cwd(path)
      text = "[FILE: #{rel}]\n[SYMBOL: #{c.sym}]\n\n" <> c.body
      %{path: rel, chunk_ix: ix, lang: to_string(lang), sym: c.sym, text: text,
        sha: :crypto.hash(:sha256, text) |> Base.encode16(case: :lower),
        tok_count: div(String.length(text),4), meta: %{}}
    end)
  end
end
