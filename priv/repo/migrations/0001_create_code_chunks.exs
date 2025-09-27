defmodule RagEx.Repo.Migrations.CreateCodeChunks do
  use Ecto.Migration

  def change do
    create table(:code_chunks) do
      add :repo_id, :string, null: false
      add :path, :string, null: false
      add :chunk_ix, :integer, null: false
      add :lang, :string, null: false
      add :sym, :string, null: false
      add :text, :text, null: false
      add :embedding, :binary, null: true   # store as binary or JSON; we'll serialize floats
      add :sha, :string, null: false
      add :tok_count, :integer, null: false, default: 0
      add :meta, :map, null: false, default: %{}
      timestamps()
    end
    create unique_index(:code_chunks, [:repo_id, :path, :chunk_ix])
    create index(:code_chunks, [:repo_id, :path])
  end
end
