defmodule RagEx.Watcher do
  use GenServer
  @debounce_ms 700

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def init(_) do
    root = Application.get_env(:rag_ex, :root, File.cwd!())
    case FileSystem.start_link(dirs: [root], name: RagEx.FileWatcher) do
      {:ok, pid} ->
        FileSystem.subscribe(pid)
        Process.send_after(self(), :initial, 50)
        {:ok, %{timer: nil}}
      {:error, reason} ->
        IO.puts("Warning: Could not start file watcher: #{inspect(reason)}")
        Process.send_after(self(), :initial, 50)
        {:ok, %{timer: nil}}
      :ignore ->
        IO.puts("Warning: File watcher returned :ignore, continuing without file watching")
        Process.send_after(self(), :initial, 50)
        {:ok, %{timer: nil}}
    end
  end

  def handle_info(:initial, state), do: (RagEx.Ingest.enqueue(); {:noreply, state})

  def handle_info({_pid, {:fs, :file_event}, _}, state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    t = Process.send_after(self(), :debounced, @debounce_ms)
    {:noreply, %{state | timer: t}}
  end

  def handle_info(:debounced, state), do: (RagEx.Ingest.enqueue(); {:noreply, %{state | timer: nil}})
end
