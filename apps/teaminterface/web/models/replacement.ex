defmodule Teaminterface.Replacement do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.ChallengeBinary
  alias Teaminterface.ChallengeSet
  alias Teaminterface.Enablement
  alias Teaminterface.Replacement
  alias Teaminterface.Repo
  alias Teaminterface.Round
  alias Teaminterface.Team

  schema "replacements" do
    field :digest, :string
    field :size, :integer
    field :scoot, :boolean, default: false

    belongs_to :team, Teaminterface.Team
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_binary, Teaminterface.ChallengeBinary

    has_one :challenge_set, through: [:challenge_binary, :challenge_set]

    timestamps
  end

  @required_fields ~w(digest size team_id round_id challenge_binary_id scoot)
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
    # |> foreign_key_constraint(:challenge_binary_id)
    |> unique_constraint(
      :team_id,
      name: :replacements_team_id_round_id_challenge_binary_id_index
    )
  end

  def filename(replacement) do
    case assoc_loaded?(replacement.challenge_binary) do
      true -> replacement.challenge_binary
      false ->
        replacement |> assoc(:challenge_binary) |> Repo.one
    end
    |> ChallengeBinary.cbid
  end

  def recent(team_id, challenge_set_id, filename, count \\ 2) do
    cb = ChallengeBinary.
    find_by_challenge_set_id_and_filename(challenge_set_id, filename)

    from(r in Teaminterface.Replacement,
      where: ((r.team_id == ^team_id) and
        (r.challenge_binary_id == ^cb.id)),
      # ordering by id means the id must be monotonically ascending, needed
      # because updated_at doesn't have enough resolution for automated tests
      order_by: [desc: r.updated_at, desc: r.id],
      select: r,
      limit: ^count)
      |> Teaminterface.Repo.all
  end

  def cb_team(_challenge_binary = %ChallengeBinary{id: cb_id},
                _team = %Team{id: team_id}) do
    from(r in Replacement,
         where: ((r.team_id == ^team_id) and
         (r.challenge_binary_id == ^cb_id)),
         order_by: [desc: r.id],
         limit: 1)
    |> Repo.one
  end

  def in_round(round_id) do
    from(r in Teaminterface.Replacement,
         where: r.round_id == ^round_id,
         preload: [:team, :challenge_binary, :challenge_set])
    |> Repo.all
  end

  def in_round_for_team(_round = %Round{id: round_id,
                                        started_at: sa,
                                        finished_at: fa},
                        _team = %Team{id: team_id})
  when is_nil(fa) or is_nil(sa) do
    from(r in Replacement,
         inner_join: cs in assoc(r, :challenge_set),
         inner_join: e in Enablement, on: ((e.challenge_set_id == cs.id) and (e.round_id == r.round_id)),
         where: ((r.round_id == ^round_id) and
         (r.team_id == ^team_id)),
         order_by: [asc: :inserted_at, asc: :id],
         preload: [:team, :challenge_binary, :challenge_set])
    |> Repo.all
  end

  def in_round_for_team(_round = %Round{id: round_id}, _team) do
    from(r in Replacement,
         inner_join: cs in assoc(r, :challenge_set),
         inner_join: e in Enablement, on: ((e.challenge_set_id == cs.id) and (e.round_id == r.round_id)),
         where: (r.round_id == ^round_id),
         order_by: [asc: :inserted_at, asc: :id],
         preload: [:team, :challenge_binary, :challenge_set])
    |> Repo.all
  end

  def get_for_team_in_round(_replacement = nil, _team, _round) do
    nil
  end

  # get own
  def get_for_team_in_round(replacement = %Replacement{team_id: team_id},
                            _team = %Team{id: team_id},
                            _round = %Round{}) do
    replacement
  end

  # get same or future
  def get_for_team_in_round(replacement = %Replacement{round_id: rep_round_id},
                            _team = %Team{},
                            _round = %Round{id: round_id})
  when (rep_round_id >= round_id) do
    nil
  end

  # get past round
  def get_for_team_in_round(replacement = %Replacement{round_id: rep_round_id},
                            _team = %Team{},
                            _round = %Round{id: round_id})
  when (rep_round_id < round_id) do
    replacement
  end

  def get_for_team_in_round(replacement_id,
                            team = %Team{},
                            round = %Round{id: round_id})
  when is_binary(replacement_id) or is_integer(replacement_id) do
    from(r in Replacement,
         inner_join: cb in assoc(r, :challenge_binary),
         inner_join: cs in assoc(cb, :challenge_set),
         inner_join: e in Enablement,
         on: ((e.challenge_set_id == cs.id) and (e.round_id == ^round_id)),
         where: (r.id == ^replacement_id),
         limit: 1,
         preload: [:challenge_binary])
    |> Repo.one
    |> get_for_team_in_round(team, round)
  end

  def from_team_in_round(team_id, round_id) do
    cset_ids = from(e in Teaminterface.Enablement,
                       where: (e.round_id == ^round_id),
                       select: e.challenge_set_id)
    |> Repo.all

    cb_ids = from(cb in ChallengeBinary,
                  where: (cb.challenge_set_id in ^cset_ids),
                  select: cb.id)
    |> Repo.all

    replacements = from(r in Teaminterface.Replacement,
                        where: ((r.team_id == ^team_id) and
                                (r.round_id <= ^round_id) and
                                (r.challenge_binary_id in ^cb_ids)),
                        distinct: r.challenge_binary_id,
                        order_by: [desc: r.updated_at, desc: r.id],
                        preload: [:challenge_set])
    |> Repo.all
  end

  def from_team_filename_and_digest(team_id, filename, digest) do
    forbid_round = Round.current_or_next

    challenge_binary = ChallengeBinary.find_by_filename(filename)

    replacements = from(r in Teaminterface.Replacement,
                        where: ((r.team_id == ^team_id) and
                                (r.challenge_binary_id == ^challenge_binary.id) and
                                (r.digest == ^digest) and
                                (r.round_id < ^forbid_round.id)),
                        order_by: [desc: :inserted_at, desc: :id],
                        limit: 1)
    |> Repo.one
  end

  def versions_of_cb(challenge_binary_id) do
    from(r in Teaminterface.Replacement,
         where: (r.challenge_binary_id == ^challenge_binary_id),
         distinct: r.digest,
         order_by: [asc: r.round_id],
         preload: [:team])
    |> Repo.all
  end

  def similar_with_round(_replacement = %Replacement{id: id,
                                                     digest: digest,
                                                     challenge_binary_id: cbid},
                         _current_round = %Round{id: max_round_id}) do
    _similar = from(r in Replacement,
                    where: ((r.id != ^id) and
                            (r.challenge_binary_id == ^cbid) and
                            (r.digest == ^digest) and
                            (r.round_id < ^max_round_id)),
                    order_by: [desc: :inserted_at, desc: :id],
                    preload: [:team])
    |> Repo.all
  end
end
