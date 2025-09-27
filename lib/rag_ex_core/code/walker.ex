defmodule RagExCore.Code.Walker do
  @moduledoc """
  File walker for discovering code files in a repository.
  """

  def list_files(root) do
    root
    |> Path.expand()
    |> File.ls!()
    |> Enum.flat_map(&list_files_recursive(Path.join(root, &1)))
  end

  defp list_files_recursive(path) do
    if File.dir?(path) do
      # Skip hidden directories and common non-code directories
      if should_skip_directory?(path) do
        []
      else
        path
        |> File.ls!()
        |> Enum.flat_map(&list_files_recursive(Path.join(path, &1)))
      end
    else
      # Only include code files
      if is_code_file?(path) do
        [path]
      else
        []
      end
    end
  end

  defp should_skip_directory?(path) do
    basename = Path.basename(path)
    basename in [".git", "_build", "deps", "node_modules", ".elixir_ls", "priv/static"]
  end

  defp is_code_file?(path) do
    ext = Path.extname(path)
    ext in [".ex", ".exs", ".heex", ".js", ".ts", ".py", ".rb", ".go", ".rs", ".java", ".c", ".cpp", ".h", ".hpp"]
  end
end
