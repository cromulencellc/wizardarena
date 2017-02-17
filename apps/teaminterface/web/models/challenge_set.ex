defmodule Teaminterface.ChallengeSet do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.ChallengeSet
  alias Teaminterface.Round

  alias Teaminterface.Repo

  schema "challenge_sets" do
    field :name, :string
    field :shortname, :string

    has_many :enablements, Teaminterface.Enablement
    has_many :challenge_binaries, Teaminterface.ChallengeBinary
    has_many :firewalls, Teaminterface.Firewall

    has_many :replacements, through: [:challenge_binaries,
                                      :replacements]

    timestamps
  end

  @required_fields ~w(name shortname)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def get_enabled_by_csid(csid) do
    Round.current_or_prev
    |> Ecto.assoc(:challenge_sets)
    |> Ecto.Query.where(shortname: ^csid)
    |> Repo.one
  end

  def find_filename(filename) do
    shortname = filename_to_shortname(filename)

    Repo.get_by(ChallengeSet, shortname: shortname)
  end

  def filename_to_shortname(filename) do
    filename
    |> String.split("_")
    |> shortname_for_splits
  end

  defp shortname_for_splits([vendor, cset_id | _rest]) do
    "#{vendor}_#{cset_id}"
  end
end
