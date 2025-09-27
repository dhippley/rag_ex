defmodule RagEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :rag_ex,
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps(),
      escript: [main_module: RagEx.CLI] # optional; also support mix release
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RagEx.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.7"},
      {:file_system, "~> 0.2"},
      {:jason, "~> 1.4"},
      {:ecto_sqlite3, "~> 0.18"},
      {:ecto_sql, "~> 3.11"},
      {:nx, "~> 0.6"}
      # If you prefer Postgres/pgvector:
      # {:postgrex, ">= 0.0.0"},
      # {:pgvector, "~> 0.3"}
    ]
  end
end
