defmodule RagEx.CLI do
  @moduledoc """
  CLI entry point for the rag_ex daemon.
  """

  def main(args) do
    {opts, _args, _invalid} = OptionParser.parse(args,
      switches: [
        root: :string,
        repo_id: :string,
        port: :integer,
        once: :boolean
      ],
      aliases: [
        r: :root,
        p: :port
      ]
    )

    # Set application environment from CLI args
    if root = opts[:root] do
      Application.put_env(:rag_ex, :root, root)
    end

    if repo_id = opts[:repo_id] do
      Application.put_env(:rag_ex, :repo_id, repo_id)
    end

    if port = opts[:port] do
      Application.put_env(:rag_ex, :port, port)
    end

    if opts[:once] do
      # Run once and exit
      IO.puts("Running one-time ingestion...")
      RagEx.Ingest.run_once()
      IO.puts("Ingestion complete.")
    else
      # Start the full daemon
      IO.puts("Starting rag_ex daemon...")
      IO.puts("Root: #{Application.get_env(:rag_ex, :root)}")
      IO.puts("Repo ID: #{Application.get_env(:rag_ex, :repo_id)}")
      IO.puts("Port: #{Application.get_env(:rag_ex, :port)}")
      IO.puts("HTTP API available at: http://127.0.0.1:#{Application.get_env(:rag_ex, :port)}")

      # Start the application
      {:ok, _} = Application.ensure_all_started(:rag_ex)

      # Keep the process alive
      Process.sleep(:infinity)
    end
  end
end
