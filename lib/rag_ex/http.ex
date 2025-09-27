defmodule RagEx.HTTP do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts)
  def init(opts) do
    port = Keyword.get(opts, :port, Application.get_env(:rag_ex, :port, 7788))
    children = [{Plug.Cowboy, scheme: :http, plug: RagEx.Router, options: [ip: {127,0,0,1}, port: port]}]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
