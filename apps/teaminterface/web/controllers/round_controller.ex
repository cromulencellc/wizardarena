defmodule Teaminterface.RoundController do
  use Teaminterface.Web, :controller

  alias Teaminterface.Round

  plug :scrub_params, "round" when action in [:create, :update]

  def index(conn, _params) do
    rounds = Repo.all(Round)
    render(conn, "index.html", rounds: rounds)
  end

  def new(conn, _params) do
    changeset = Round.changeset(%Round{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"round" => round_params}) do
    changeset = Round.changeset(%Round{}, round_params)

    case Repo.insert(changeset) do
      {:ok, _round} ->
        conn
        |> put_flash(:info, "Round created successfully.")
        |> redirect(to: round_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    round = Repo.get!(Round, id)
    render(conn, "show.html", round: round)
  end

  def edit(conn, %{"id" => id}) do
    round = Repo.get!(Round, id)
    changeset = Round.changeset(round)
    render(conn, "edit.html", round: round, changeset: changeset)
  end

  def update(conn, %{"id" => id, "round" => round_params}) do
    round = Repo.get!(Round, id)
    changeset = Round.changeset(round, round_params)

    case Repo.update(changeset) do
      {:ok, round} ->
        conn
        |> put_flash(:info, "Round updated successfully.")
        |> redirect(to: round_path(conn, :show, round))
      {:error, changeset} ->
        render(conn, "edit.html", round: round, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    round = Repo.get!(Round, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(round)

    conn
    |> put_flash(:info, "Round deleted successfully.")
    |> redirect(to: round_path(conn, :index))
  end
end
