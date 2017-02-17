defmodule Teaminterface.ChallengeBinary do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.ChallengeBinary
  alias Teaminterface.ChallengeSet
  alias Teaminterface.Enablement
  alias Teaminterface.Repo
  alias Teaminterface.Round

  schema "challenge_binaries" do
    field :index, :integer
    field :size, :integer
    field :patched_size, :integer
    belongs_to :challenge_set, Teaminterface.ChallengeSet
    has_many :replacements, Teaminterface.Replacement

    has_many :enablements, through: [:challenge_set, :enablements]

    timestamps
  end

  @required_fields ~w(index size patched_size challenge_set_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:challenge_set_id)
  end

  def cbid(challenge_binary, cset = %ChallengeSet{}) do
    %ChallengeBinary{challenge_binary | challenge_set: cset}
    |> cbid
  end

  def cbid(%ChallengeBinary{index: 0} = challenge_binary) do
    cset = case assoc_loaded?(challenge_binary.challenge_set) do
             true -> challenge_binary.challenge_set
             false ->
               challenge_binary |> assoc(:challenge_set) |> Repo.one
           end

    cset.shortname
  end


  def cbid(%ChallengeBinary{index: idx} = challenge_binary) when idx > 0 do
    cset = case assoc_loaded?(challenge_binary.challenge_set) do
             true -> challenge_binary.challenge_set
             false ->
               challenge_binary |> assoc(:challenge_set) |> Repo.one
           end

    "#{cset.shortname}_#{idx}"
  end

  def find_enabled_by_filename(filename) do
    cb = find_by_filename(filename)
    round = Round.current_or_prev
    enablement = cond do
      nil == cb -> nil
      [] == cb -> nil
      nil == round -> nil
        enablement = (from(e in assoc(cb, :enablements),
                           where: e.round_id == ^(round.id))
          |> Repo.one) ->
          enablement
        true -> nil
    end

    case enablement do
      nil -> nil
      %Enablement{} -> cb
    end
  end

  def find_by_filename(filename) do
    filename
    |> ChallengeSet.find_filename()
    |> find_by_challenge_set_id_and_filename(filename)
  end

  def find_by_challenge_set_id_and_filename(nil, _filename) do
    nil
  end

  def find_by_challenge_set_id_and_filename(challenge_set = %ChallengeSet{},
                                            filename) do
    find_by_challenge_set_id_and_filename(challenge_set.id, filename)
  end

  def find_by_challenge_set_id_and_filename(challenge_set_id, filename) do
    index = get_index_from_filename(filename)

    Repo.get_by(ChallengeBinary,
                challenge_set_id: challenge_set_id,
                index: index)
  end

  def get_index_from_filename(filename) when is_binary(filename) do
    filename
    |> String.split("_")
    |> get_index_from_filename
  end

  def get_index_from_filename([_vendor, _id]) do
    0
  end

  def get_index_from_filename([_vendor, _id, index]) do
    String.to_integer(index)
  end
end
