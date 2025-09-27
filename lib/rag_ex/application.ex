defmodule RagEx.Application do
  use Application
  def start(_type, _args) do
    children = [
      RagEx.Repo,
      RagEx.HTTP,
      RagEx.Watcher
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
