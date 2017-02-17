defmodule Teaminterface.PollerController do
  use Teaminterface.Web, :controller
  import Ecto.Query

  alias Teaminterface.Poller

  plug :scrub_params, "poller" when action in [:create, :update]

  def index(conn, params) do
    q = Poller
    |> join(:inner, [p], c in assoc(p, :challenge_set))
    |> order_by([p, c], [desc: p.id, desc: p.round_id])
    |> preload([p, c], [challenge_set: c])

    q = cond do
      challenge_set_id = Map.get(params, "challenge_set_id", false) ->
        q |> where([p, c], p.challenge_set_id == ^challenge_set_id)
      not_challenge_set_id = Map.get(params, "not_challenge_set_id", false) ->
        q |> where([p, c], p.challenge_set_id != ^not_challenge_set_id)
      true -> q
    end

    q = cond do
      round_id = Map.get(params, "round_id", false) ->
        q |> where([p, c], p.round_id == ^round_id)
      not_round_id = Map.get(params, "not_round_id", false) ->
        q |> where([p, c], p.round_id != ^not_round_id)
      true -> q
    end

    pagination = q |> Repo.paginate(params)

    symbolized_params = params
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)

    pollers = pagination.entries

    render(conn, "index.html", title: "pollers",
           pagination: pagination,
           pollers: pollers,
           symbolized_params: symbolized_params)
  end

  def new(conn, _params) do
    changeset = Poller.changeset(%Poller{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"poller" => poller_params}) do
    changeset = Poller.changeset(%Poller{}, poller_params)

    case Repo.insert(changeset) do
      {:ok, _poller} ->
        conn
        |> put_flash(:info, "Poller created successfully.")
        |> redirect(to: poller_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    poller = Repo.get!(Poller, id)
    render(conn, "show.html", poller: poller)
  end

  def edit(conn, %{"id" => id}) do
    poller = Repo.get!(Poller, id)
    changeset = Poller.changeset(poller)
    render(conn, "edit.html", poller: poller, changeset: changeset)
  end

  def update(conn, %{"id" => id, "poller" => poller_params}) do
    poller = Repo.get!(Poller, id)
    changeset = Poller.changeset(poller, poller_params)

    case Repo.update(changeset) do
      {:ok, poller} ->
        conn
        |> put_flash(:info, "Poller updated successfully.")
        |> redirect(to: poller_path(conn, :show, poller))
      {:error, changeset} ->
        render(conn, "edit.html", poller: poller, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    poller = Repo.get!(Poller, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(poller)

    conn
    |> put_flash(:info, "Poller deleted successfully.")
    |> redirect(to: poller_path(conn, :index))
  end
end
