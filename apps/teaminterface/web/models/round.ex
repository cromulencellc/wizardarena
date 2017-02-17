defmodule Teaminterface.Round do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2, preload: 2]

  alias Teaminterface.Repo

  schema "rounds" do
    field :nickname, :string
    field :started_at, Timex.Ecto.DateTime
    field :finished_at, Timex.Ecto.DateTime
    field :secret, :binary
    field :seed, :binary

    has_many :enablements, Teaminterface.Enablement
    has_many(:challenge_sets, through: [:enablements, :challenge_set])
    has_many(:challenge_binaries, through: [:enablements,
                                            :challenge_set,
                                            :challenge_binaries])

    timestamps
  end

  @required_fields ~w()
  @optional_fields ~w(nickname started_at finished_at)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:nickname)
  end

  def current() do
    from(r in Teaminterface.Round,
         where: (is_nil(r.finished_at) and not is_nil(r.started_at)),
         select: r)
    |> Repo.one
  end

  def current_or_next() do
    from(r in Teaminterface.Round,
         where: (is_nil(r.finished_at)),
         limit: 1,
         order_by: [asc: :id])
    |> Repo.one
  end

  def current_or_prev() do
    cond do
      fw = current() -> fw
      true -> prev
    end
  end

  def recent(count \\ 5) do
    from(r in Teaminterface.Round,
         where: not is_nil(r.started_at),
         limit: ^count,
         order_by: [desc: :id])
    |> Repo.all
  end

  def prev do
    from(r in Teaminterface.Round,
         where: not is_nil(r.finished_at),
         order_by: [desc: :id],
         limit: 1)
    |> Repo.one
  end

  def all_past_rounds do
    from(r in Teaminterface.Round,
         where: not is_nil(r.started_at),
         order_by: [desc: :id])
    |> Repo.all
  end


  def get_past_round(round_id) when is_binary(round_id) do
    round_id
    |> String.to_integer
    |> get_past_round
  end

  def get_past_round(round_id) do
    from(r in Teaminterface.Round,
         where: (not is_nil(r.finished_at) and (r.id == ^round_id)))
    |> Repo.one
  end

  def challenge_sets(round) do
    round
    |> Ecto.assoc(:challenge_sets)
    |> preload(:challenge_binaries)
    |> Teaminterface.Repo.all
  end
end
