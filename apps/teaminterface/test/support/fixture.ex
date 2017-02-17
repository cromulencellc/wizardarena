defmodule Teaminterface.ConnCase.Fixture do
  def fixture(filename) do
    fixture(filename, Path.rootname(filename))
  end

  def fixture(filename, http_filename) do
    %Plug.Upload{path: fixture_path(filename),
                 filename: http_filename}
  end

  def fixture_path(filename) do
    __DIR__
    |> Path.join("./fixtures")
    |> Path.join(filename)
    |> Path.expand
  end
end
