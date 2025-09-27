defmodule RagEx.Repo do
  use Ecto.Repo,
    otp_app: :rag_ex,
    adapter: Ecto.Adapters.SQLite3
end
