defmodule RagEx.Router do
  use Plug.Router
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  get "/health" do
    send_resp(conn, 200, ~s({"ok":true}))
  end

  get "/v1/context" do
    repo = Application.get_env(:rag_ex, :repo_id)
    query = conn.params["query"] || ""
    budget = parse_int(conn.params["budget"], 3500)
    ctx = RagEx.Query.context(repo, query, budget)
    send_json_response(conn, 200, %{repo_id: repo, query: query, budget: budget, context: ctx})
  end

  get "/v1/search" do
    repo = Application.get_env(:rag_ex, :repo_id)
    query = conn.params["query"] || ""
    k = parse_int(conn.params["k"], 20)
    res = RagEx.Query.search(repo, query, k)
    send_json_response(conn, 200, %{results: res})
  end

  post "/v1/ingest" do
    RagEx.Ingest.enqueue()
    send_json_response(conn, 202, %{status: "queued"})
  end

  match _ do
    send_resp(conn, 404, ~s({"error":"not_found"}))
  end

  defp send_json_response(conn, status, data) do
    send_resp(conn, status, Jason.encode!(data))
  end

  defp parse_int(nil, default), do: default
  defp parse_int(s, default) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      _ -> default
    end
  end
  defp parse_int(_, default), do: default
end
