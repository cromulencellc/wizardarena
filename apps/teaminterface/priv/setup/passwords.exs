defmodule Blah do
  def read(fname) do
    __DIR__
    |> Path.join("./#{fname}")
    |> Path.expand
    |> File.stream!([:read], :line)
    |> Enum.map(&String.strip(&1))
  end
  
  def pick(list) do
    Enum.random(list)
  end

  def run() do
    _teams = __DIR__
    |> Path.join("../repo/teams.tsv")
    |> Path.expand
    |> File.stream!([:read], :line)
    |> Stream.each(fn(_tl) ->
      [read("breach.csv"),
       read("passwords.csv"),
       read("breads.csv")]
      |> Enum.map(&pick(&1))
      |> List.insert_at(2, "on")
      |> List.insert_at(1, "and")
      |> Enum.join(" ")
      |> IO.puts
    end)
    |> Enum.to_list
  end
end

Blah.run
