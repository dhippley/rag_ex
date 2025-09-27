import Config

config :rag_ex,
  ecto_repos: [RagEx.Repo],
  port: 7788,
  root: File.cwd!(),
  repo_id: Path.basename(File.cwd!())

config :rag_ex, RagEx.Repo,
  database: Path.expand("data/rag_ex.sqlite3", File.cwd!()),
  pool_size: 5
