defmodule Teaminterface.Proof do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.Repo

  alias Teaminterface.ChallengeSet
  alias Teaminterface.Proof
  alias Teaminterface.Team

  schema "proofs" do
    field :digest, :string
    field :throws, :integer
    belongs_to :team, Teaminterface.Team
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_set, Teaminterface.ChallengeSet
    belongs_to :target, Teaminterface.Team

    has_many :proof_feedbacks, Teaminterface.ProofFeedback

    timestamps
  end

  @required_fields ~w(digest throws)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:round_id)
    |> foreign_key_constraint(:challenge_set_id)
    |> foreign_key_constraint(:target_id)
  end

  def live_for_team_and_cset(_team = %Team{id: team_id},
                             _cset = %ChallengeSet{id: cset_id}) do
    from(p in Proof,
         where: ((p.team_id == ^team_id) and
                 (p.challenge_set_id == ^cset_id)),
         distinct: p.target_id,
         order_by: [desc: :inserted_at, desc: :id],
         preload: [:target])
    |> Repo.all
  end
end
