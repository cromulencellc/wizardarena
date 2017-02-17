defmodule Teaminterface.Enablement do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.Repo

  alias Teaminterface.ChallengeBinary
  alias Teaminterface.Enablement
  alias Teaminterface.Round

  schema "enablements" do
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_set, Teaminterface.ChallengeSet

    timestamps
  end

  @required_fields ~w(round_id challenge_set_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:round_id)
    |> foreign_key_constraint(:challenge_set_id)
  end

  def current_for_cb(_cb = %ChallengeBinary{challenge_set_id: csid}) do
    round = Round.current

    Repo.get_by(Enablement, challenge_set_id: csid, round_id: round.id)
  end

  def enable_range(cset_id, start_round_id, end_round_id) do
    q = """
    INSERT INTO enablements
    (challenge_set_id, round_id, inserted_at, updated_at)
    (SELECT $1, r.id, NOW(), NOW()
    FROM rounds AS r
    WHERE r.id >= $2 AND r.id <= $3)
    ON CONFLICT DO NOTHING
    """

    Ecto.Adapters.SQL.query(Repo, q, [cset_id, start_round_id, end_round_id])
  end

  def disable_range(cset_id, start_round_id, end_round_id) do
    q = """
    DELETE FROM enablements AS e
    WHERE
      e.challenge_set_id = $1 AND
      e.round_id >= $2 AND
      e.round_id <= $3
    """

    Ecto.Adapters.SQL.query(Repo, q, [cset_id, start_round_id, end_round_id])
  end
end
