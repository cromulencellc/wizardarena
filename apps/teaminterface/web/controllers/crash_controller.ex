defmodule Teaminterface.CrashController do
  use Teaminterface.Web, :controller
  import Ecto.Query

  alias Teaminterface.Crash

  plug :scrub_params, "crash" when action in [:create, :update]

  def index(conn, params) do
    q = Crash
    |> join(:inner, [c], t in assoc(c, :team))
    |> join(:inner, [c, t], cb in assoc(c, :challenge_binary))
    |> join(:inner, [c, t, cb], cs in assoc(cb, :challenge_set))
    |> order_by([c, t, cb, cs], [desc: c.id])
    |> preload([c, t, cb, cs], [team: t,
                                challenge_binary: cb,
                                challenge_set: cs])

    q = cond do
      team_id = Map.get(params, "team_id", false) ->
        q |> where([c, t, cb, cs], c.team_id == ^team_id)
      not_team_id = Map.get(params, "not_team_id", false) ->
        q |> where([c, t, cb, cs], c.team_id != ^not_team_id)
      true -> q
    end

    q = cond do
      challenge_set_id = Map.get(params, "challenge_set_id", false) ->
        q |> where([c, t, cb, cs], cb.challenge_set_id == ^challenge_set_id)
      not_challenge_set_id = Map.get(params, "not_challenge_set_id", false) ->
        q |> where([c, t, cb, cs], cb.challenge_set_id != ^not_challenge_set_id)
      true -> q
    end

    q = cond do
      challenge_binary_id = Map.get(params, "challenge_binary_id", false) ->
        q |> where([c, t, cb, cs], cb.id == ^challenge_binary_id)
      not_challenge_binary_id = Map.get(params, "not_challenge_binary_id", false) ->
        q |> where([c, t, cb, cs], cb.id != ^not_challenge_binary_id)
      true -> q
    end

    crashes = q |> Repo.paginate(params)

    symbolized_params = params
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)

    render(conn, "index.html", title: "crashes",
           pagination: crashes,
           crashes: crashes.entries,
           symbolized_params: symbolized_params)
  end

  def new(conn, _params) do
    changeset = Crash.changeset(%Crash{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"crash" => crash_params}) do
    changeset = Crash.changeset(%Crash{}, crash_params)

    case Repo.insert(changeset) do
      {:ok, _crash} ->
        conn
        |> put_flash(:info, "Crash created successfully.")
        |> redirect(to: crash_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    crash = Repo.get!(Crash, id)
    render(conn, "show.html", crash: crash)
  end

  def edit(conn, %{"id" => id}) do
    crash = Repo.get!(Crash, id)
    changeset = Crash.changeset(crash)
    render(conn, "edit.html", crash: crash, changeset: changeset)
  end

  def update(conn, %{"id" => id, "crash" => crash_params}) do
    crash = Repo.get!(Crash, id)
    changeset = Crash.changeset(crash, crash_params)

    case Repo.update(changeset) do
      {:ok, crash} ->
        conn
        |> put_flash(:info, "Crash updated successfully.")
        |> redirect(to: crash_path(conn, :show, crash))
      {:error, changeset} ->
        render(conn, "edit.html", crash: crash, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    crash = Repo.get!(Crash, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(crash)

    conn
    |> put_flash(:info, "Crash deleted successfully.")
    |> redirect(to: crash_path(conn, :index))
  end
end
