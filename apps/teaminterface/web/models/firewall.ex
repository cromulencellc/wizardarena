defmodule Teaminterface.Firewall do
  use Teaminterface.Web, :model

  alias Teaminterface.ChallengeSet
  alias Teaminterface.Enablement
  alias Teaminterface.Firewall
  alias Teaminterface.Repo
  alias Teaminterface.Round
  alias Teaminterface.Team

  schema "firewalls" do
    field :digest, :string
    field :scoot, :boolean, default: false

    belongs_to :team, Teaminterface.Team
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_set, Teaminterface.ChallengeSet

    timestamps
  end

  @required_fields ~w(digest team_id round_id challenge_set_id scoot)
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
  end

  def in_round(round_id) do
    from(f in Teaminterface.Firewall,
         where: f.round_id == ^round_id,
         preload: [:challenge_set, :team]
    )
    |> Repo.all
  end

  def in_round_for_team(_round = %Round{id: round_id,
                                        started_at: sa,
                                        finished_at: fa},
                        _team = %Team{id: team_id})
  when is_nil(fa) or is_nil(sa) do
    from(f in Firewall,
         inner_join: cs in assoc(f, :challenge_set),
         inner_join: e in Enablement, on: ((e.challenge_set_id == cs.id) and (e.round_id == f.round_id)),
         where: ((f.round_id == ^round_id) and
                 (f.team_id == ^team_id)),
         order_by: [asc: :inserted_at, asc: :id],
         preload: [:team, :challenge_set])
    |> Repo.all
  end

  def in_round_for_team(_round = %Round{id: round_id}, _team) do
    from(f in Firewall,
         inner_join: cs in assoc(f, :challenge_set),
         inner_join: e in Enablement, on: ((e.challenge_set_id == cs.id) and (e.round_id == f.round_id)),
         where: (f.round_id == ^round_id),
         order_by: [asc: :inserted_at, asc: :id],
         preload: [:team, :challenge_set])
    |> Repo.all
  end

  def live_for_cset(_challenge_set = %ChallengeSet{id: cset_id}) do
    round_id = Round.current_or_prev.id

    from(f in Firewall,
         where: ((f.round_id < ^round_id) and
                 (f.challenge_set_id == ^cset_id)),
         distinct: f.team_id,
         order_by: [desc: :inserted_at, desc: :id],
         preload: [:team])
    |> Repo.all
  end

  def pending(_team = %Team{id: team_id},
              _challenge_set = %ChallengeSet{id: cset_id}) do
    round_id = Round.current_or_prev.id
    from(f in Firewall,
         where: ((f.round_id == ^round_id) and
                 (f.team_id == ^team_id) and
                 (f.challenge_set_id == ^cset_id)),
         preload: [:team])
    |> Repo.one
  end

  def cset_team(_challenge_set = %ChallengeSet{id: cset_id},
                _team = %Team{id: team_id}) do
    from(f in Firewall,
         where: ((f.team_id == ^team_id) and
         (f.challenge_set_id == ^cset_id)),
         order_by: [desc: f.id],
         limit: 1)
    |> Repo.one
  end

  # get own firewall
  def get_for_team_in_round(firewall = %Firewall{team_id: team_id},
                            _team = %Team{id: team_id},
                            _round) do
    firewall
  end

  # get same or future round
  def get_for_team_in_round(_firewall = %Firewall{round_id: fw_round_id},
                            _team = %Team{},
                            _round = %Round{id: round_id})
  when (fw_round_id >= round_id) do
    nil
  end

  # get past round
  def get_for_team_in_round(firewall = %Firewall{round_id: fw_round_id},
                            _team = %Team{},
                            _round = %Round{id: round_id})
  when (fw_round_id < round_id) do
    firewall
  end

  def get_for_team_in_round(nil, _team, _round) do
    nil
  end

  def get_for_team_in_round(firewall_id, team, round = %Round{id: round_id}) do
    _fw = from(f in Firewall,
              inner_join: cs in assoc(f, :challenge_set),
              inner_join: e in Enablement,
              on: ((e.challenge_set_id == cs.id) and (e.round_id == ^round_id)),
              where: f.id == ^firewall_id,
              limit: 1,
              preload: [:challenge_set])
    |> Repo.one
    |> get_for_team_in_round(team, round)
  end

  def from_team_in_round(team_id, round_id) do
    cset_ids = from(e in Teaminterface.Enablement,
                    where: (e.round_id == ^round_id),
                    select: e.challenge_set_id)
    |> Repo.all

    _firewalls = from(f in Teaminterface.Firewall,
                        where: ((f.team_id == ^team_id) and
                                (f.round_id <= ^round_id) and
                                (f.challenge_set_id in ^cset_ids)),
                        distinct: f.challenge_set_id,
                        order_by: [desc: f.updated_at, desc: f.id],
                        preload: [:challenge_set, :team])
    |> Repo.all
  end

  def from_team_and_digest(team_id, digest) do
    forbid_round = Round.current_or_next

    _firewalls = from(f in Teaminterface.Firewall,
                     where: ((f.team_id == ^team_id) and
                             (f.digest == ^digest) and
                             (f.round_id < ^forbid_round.id)),
                     order_by: [desc: :inserted_at, desc: :id],
                     limit: 1,
                     preload: [:challenge_set, :round])
    |> Repo.one
  end

  def similar_with_round(_firewall = %Firewall{id: id,
                                               digest: digest,
                                               challenge_set_id: csid},
                         _current_round = %Round{id: max_round_id}) do

    _similar = from(f in Firewall,
                    where: ((f.id != ^id) and
                            (f.challenge_set_id == ^csid) and
                            (f.digest == ^digest) and
                    (f.round_id < ^max_round_id)),
                    order_by: [desc: :inserted_at, desc: :id],
                    preload: [:team])
    |> Repo.all
  end
end
