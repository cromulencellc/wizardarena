defmodule Teaminterface.Team do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.Repo
  alias Teaminterface.Team

  schema "teams" do
    field :name, :string
    field :shortname, :string
    field :displayname, :string
    field :color, :string
    field :password_digest, :string
    field :score, :float

    timestamps
  end

  @required_fields ~w(name shortname score password_digest)
  @optional_fields ~w(color displayname)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{})

  def changeset(model, params = %{"password" => ""}) do
    params_without_password = Map.delete(params, "password")

    changeset(model, params_without_password)
  end

  def changeset(model, params = %{"password" => nil}) do
    params_without_password = Map.delete(params, "password")

    changeset(model, params_without_password)
  end

  def changeset(model, params = %{"password" => ""}) do
    params_without_password = Map.delete(params, "password")

    model
    |> changeset(params_without_password)
  end

  def changeset(model, params = %{"password" => new_password}) do
    params_without_password = Map.delete(params, "password")

    model
    |> update_password(new_password)
    |> changeset(params_without_password)
  end

  def changeset(model, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def update_password(team, new_password) do
    new_digest = Comeonin.Bcrypt.hashpwsalt(new_password)

    changeset(team, %{password_digest: new_digest})
  end

  def scoreboard() do
    from(t in Teaminterface.Team,
         select: [t.id, t.score],
         order_by: [asc: t.name])
    |> Repo.all
    |> Stream.with_index()
    |> Stream.map(fn({[id, score], place}) ->
      %{
        "score" => 1,
        # "score" => ((score * 100) |> Float.round |> trunc),
        "team" => id,
        "place" => place + 1,
        "rank" => place + 1
       }
    end)
    |> Enum.reverse()
  end

  def human_scoreboard() do
    from(t in Team,
         order_by: [asc: t.name])
    |> Repo.all
    |> Stream.with_index()
    |> Stream.map(fn({team, place}) ->
      %{
        "score" => 1,
        # "score" => ((team.score * 100) |> Float.round |> trunc),
        "team" => team,
        "place" => place + 1}
    end)
  end

  def seed_from_tsv_row(tsv_row) do
    [id, name, shortname, _prefix, color, password | _rest] = tsv_row
    |> String.split("\t")
    |> Enum.map(&String.trim(&1))

    seed_row(Integer.parse(id), name, shortname, color, password)
  end

  defp seed_row(:error, _, _, color, password) do
    nil
  end

  defp seed_row({id, _rest}, name, shortname, color, password) do
    case Repo.get(Team, id) do
      nil -> %Team{id: id}
      team -> team
    end
    |> Team.changeset(%{name: name,
                        shortname: shortname,
                        color: color,
                        score: 0.0})
    |> Team.update_password(password)
    |> Repo.insert_or_update!
  end

  def picker do
    from(t in Team,
         select: {t.name, t.id},
         order_by: [asc: :id])
    |> Repo.all
  end
end
