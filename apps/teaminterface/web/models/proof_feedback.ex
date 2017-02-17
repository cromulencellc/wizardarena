defmodule Teaminterface.ProofFeedback do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.ChallengeSet
  alias Teaminterface.Proof
  alias Teaminterface.ProofFeedback
  alias Teaminterface.Round
  alias Teaminterface.Team

  alias Teaminterface.Repo

  schema "proof_feedbacks" do
    field :throw, :integer
    field :successful, :boolean, default: false
    field :error, :string
    field :signal, :integer
    field :type, :integer
    field :seed, :binary
    field :pov_seed, :binary
    belongs_to :proof, Proof
    belongs_to :round, Round
    has_one :challenge_set, through: [:proof, :challenge_set]
    has_one :team, through: [:proof, :team]
    has_one :target, through: [:proof, :target]

    timestamps
  end

  @required_fields ~w(throw successful error signal)
  @optional_fields ~w(type seed pov_seed proof_id round_id)

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
    _feedbacks = from(f in ProofFeedback,
                      join: p in Proof, on: f.proof_id == p.id,
                      join: t in assoc(p, :target),
                      where: ((f.round_id == ^round_id) and
                              (p.team_id == ^team_id) and
                              (p.round_id < ^round_id)),
                      order_by: [asc: f.id],
                     preload: [:challenge_set, :target])
    |> Repo.all
  end

  def as_feedback_json(feedback) do
    cset = case assoc_loaded?(feedback.challenge_set) do
             true -> feedback.challenge_set
             false ->
               feedback |> assoc(:challenge_set) |> Repo.one
           end

    target = case assoc_loaded?(feedback.target) do
              true -> feedback.target
              false ->
                feedback |> assoc(:target) |> Repo.one
            end

    initial = %{"csid" => (cset.id |> Integer.to_string),
                "team" => target.id,
                "throw" => feedback.throw}

    case feedback.successful do
      true -> %{"result" => "success"}
      false ->
        %{"result" => "fail",
          "error" => feedback.error}
    end
    |> Map.merge(initial)
  end

  def paginated(_team = %Team{id: team_id},
                _cset = %ChallengeSet{id: cset_id},
                page) do
    last_complete_round = Teaminterface.Round.prev

    base = from(pf in ProofFeedback,
                join: p in assoc(pf, :proof),
                join: cs in assoc(p, :challenge_set),
                join: t in assoc(p, :target),
                where: ((p.challenge_set_id == ^cset_id) and
                        (p.team_id == ^team_id) and
                        (p.round_id <= ^last_complete_round.id)))

    feedbacks = from([pf, p, cs, t] in base,
                     order_by: [desc: pf.inserted_at, desc: pf.id],
                     limit: 50,
                     offset: ^((page - 1) * 50),
                     preload: [proof: p, target: t])
    |> Repo.all

    count = from([pf, p, cs, t] in base,
                 select: count(pf.id))
    |> Repo.one

    %{count: count, feedbacks: feedbacks}
  end
end
