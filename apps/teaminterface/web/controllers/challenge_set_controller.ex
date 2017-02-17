defmodule Teaminterface.ChallengeSetController do
  use Teaminterface.Web, :controller

  alias Teaminterface.ChallengeSet

  plug :scrub_params, "challenge_set" when action in [:create, :update]

  def index(conn, _params) do
    challenge_sets = Repo.all(ChallengeSet)
    render(conn, "index.html", challenge_sets: challenge_sets)
  end

  def new(conn, _params) do
    changeset = ChallengeSet.changeset(%ChallengeSet{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"challenge_set" => challenge_set_params}) do
    changeset = ChallengeSet.changeset(%ChallengeSet{}, challenge_set_params)

    case Repo.insert(changeset) do
      {:ok, _challenge_set} ->
        conn
        |> put_flash(:info, "Challenge set created successfully.")
        |> redirect(to: challenge_set_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    challenge_set = Repo.get!(ChallengeSet, id)
    render(conn, "show.html", challenge_set: challenge_set)
  end

  def edit(conn, %{"id" => id}) do
    challenge_set = Repo.get!(ChallengeSet, id)
    changeset = ChallengeSet.changeset(challenge_set)
    render(conn, "edit.html", challenge_set: challenge_set, changeset: changeset)
  end

  def update(conn, %{"id" => id, "challenge_set" => challenge_set_params}) do
    challenge_set = Repo.get!(ChallengeSet, id)
    changeset = ChallengeSet.changeset(challenge_set, challenge_set_params)

    case Repo.update(changeset) do
      {:ok, challenge_set} ->
        conn
        |> put_flash(:info, "Challenge set updated successfully.")
        |> redirect(to: challenge_set_path(conn, :show, challenge_set))
      {:error, changeset} ->
        render(conn, "edit.html", challenge_set: challenge_set, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    challenge_set = Repo.get!(ChallengeSet, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(challenge_set)

    conn
    |> put_flash(:info, "Challenge set deleted successfully.")
    |> redirect(to: challenge_set_path(conn, :index))
  end
end
