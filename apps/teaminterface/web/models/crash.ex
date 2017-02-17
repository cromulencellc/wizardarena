defmodule Teaminterface.Crash do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.Crash
  alias Teaminterface.ChallengeBinary
  alias Teaminterface.ChallengeSet
  alias Teaminterface.Team

  alias Teaminterface.Repo

  schema "crashes" do
    field :signal, :integer
    field :timestamp, Timex.Ecto.DateTime
    belongs_to :team, Teaminterface.Team
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_binary, ChallengeBinary

    has_one :challenge_set, through: [:challenge_binary, :challenge_set]

    timestamps
  end

  @required_fields ~w(signal)
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

  def for_team_in_round(_team = %Team{id: team_id}, round) do
    for_team_in_round(team_id, round)
  end

  def for_team_in_round(team_id, round_id) do
    from(c in Crash,
         join: cb in assoc(c, :challenge_binary),
         join: cs in assoc(c, :challenge_set),
         where: ((c.round_id == ^round_id) and
                 (c.team_id == ^team_id)),
         preload: [:challenge_binary, :challenge_set])
    |> Repo.all
  end

  def as_feedback_json(crash) do
    cb = case assoc_loaded?(crash.challenge_binary) do
           true -> crash.challenge_binary
           false ->
             crash |> assoc(:challenge_binary) |> Repo.one
         end

    timestamp = Timex.to_unix(crash.inserted_at)

    %{"csid" => (cb.challenge_set_id |> Integer.to_string),
      "cbid" => ChallengeBinary.cbid(cb),
      "timestamp" => timestamp,
      "signal" => crash.signal
     }
  end

  def paginated(_team = %Team{id: team_id},
                _cset = %ChallengeSet{id: cset_id},
                page) do
    last_complete_round = Teaminterface.Round.prev

    base = from(c in Crash,
                join: cb in ChallengeBinary, on: c.challenge_binary_id == cb.id,
                join: cs in ChallengeSet, on: cb.challenge_set_id == cs.id,
                where: ((cb.challenge_set_id == ^cset_id) and
                        (c.team_id == ^team_id) and
                        (c.round_id <= ^last_complete_round.id)))

    feedbacks = from([c, cb, cs] in base,
                     order_by: [desc: c.inserted_at, desc: c.id],
                     limit: 50,
                     offset: ^((page - 1) * 50),
                     preload: [challenge_binary: cb,
                               challenge_set: cs])
    |> Repo.all

    count = from([c, cb] in base,
                 select: count(c.id))
    |> Repo.one

    %{count: count, crashes: feedbacks}
  end
end
