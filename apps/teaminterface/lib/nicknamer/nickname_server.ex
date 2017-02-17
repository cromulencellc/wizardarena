defmodule Nicknamer.NicknameServer do
  defstruct [:noun_count, :nouns, :adjective_count, :adjectives]
  @type t :: %__MODULE__ {
    noun_count: non_neg_integer(),
    nouns: %{non_neg_integer() => String.t},
    adjective_count: non_neg_integer(),
    adjectives: %{non_neg_integer() => String.t}
  }
  use GenServer

  # client

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, [], opts)
  end

  def adjective(idx) do
    GenServer.call(:nickname_server, {:adjective, idx})
  end

  def noun(idx) do
    GenServer.call(:nickname_server, {:noun, idx})
  end

  # callbacks

  def init([]) do
    {noun_count, nouns} = load_nouns
    {adjective_count, adjectives} = load_adjectives

    {:ok,
     %__MODULE__{
       noun_count: noun_count,
       nouns: nouns,
       adjective_count: adjective_count,
       adjectives: adjectives
     }}
  end

  def handle_call({:noun, idx},
                  _from,
                  %__MODULE__{noun_count: count,
                              nouns: nouns} = state) do
    noun = Map.get(nouns, rem(idx, count))

    {:reply, noun, state}
  end

  def handle_call({:adjective, idx},
                  _from,
                  %__MODULE__{adjective_count: count,
                              adjectives: adjectives} = state) do
    adjective = Map.get(adjectives, rem(idx, count))

    {:reply, adjective, state}
  end

  # internal

  defp load_file(fname) do
    __DIR__
    |> Path.join("./#{fname}")
    |> Path.expand
    |> File.stream!([:read], :line)
    |> Enum.shuffle
    |> Stream.with_index
    |> Enum.reduce({0, %{}}, fn({word, index}, {cnt, acc}) ->
      stripped_word = String.strip(word)
      {cnt + 1, Map.put(acc, index, stripped_word)}
    end)
  end

  defp load_nouns do
    load_file "nouns.csv"
  end

  defp load_adjectives do
    load_file "adjectives.csv"
  end
end
