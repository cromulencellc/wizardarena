defmodule Cgcef.File do
  def open(filename, do: do_clause) when is_binary(filename) do
    case Elixir.File.open(filename, [:read], do_clause) do
      {:ok, result} -> result
      other -> raise(other)
    end
  end

  def read_bytes(fp, start, count) do
    :file.position(fp, {:bof, start})
    IO.binread(fp, count)
  end
end
