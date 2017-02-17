defmodule Teaminterface.ChallengeSetAliasController do
  use Teaminterface.Web, :controller

  alias Teaminterface.ChallengeSetAlias

  plug :scrub_params, "challenge_set_alias" when action in [:create, :update]

  def index(conn, _params) do
    challenge_set_aliases = Repo.all(ChallengeSetAlias)
    render(conn, "index.html", challenge_set_aliases: challenge_set_aliases)
  end

  def new(conn, _params) do
    changeset = ChallengeSetAlias.changeset(%ChallengeSetAlias{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"challenge_set_alias" => challenge_set_alias_params}) do
    changeset = ChallengeSetAlias.changeset(%ChallengeSetAlias{}, challenge_set_alias_params)

    case Repo.insert(changeset) do
      {:ok, _challenge_set_alias} ->
        conn
        |> put_flash(:info, "Challenge set alias created successfully.")
        |> redirect(to: challenge_set_alias_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    challenge_set_alias = Repo.get!(ChallengeSetAlias, id)
    render(conn, "show.html", challenge_set_alias: challenge_set_alias)
  end

  def edit(conn, %{"id" => id}) do
    challenge_set_alias = Repo.get!(ChallengeSetAlias, id)
    changeset = ChallengeSetAlias.changeset(challenge_set_alias)
    render(conn, "edit.html", challenge_set_alias: challenge_set_alias, changeset: changeset)
  end

  def update(conn, %{"id" => id, "challenge_set_alias" => challenge_set_alias_params}) do
    challenge_set_alias = Repo.get!(ChallengeSetAlias, id)
    changeset = ChallengeSetAlias.changeset(challenge_set_alias, challenge_set_alias_params)

    case Repo.update(changeset) do
      {:ok, challenge_set_alias} ->
        conn
        |> put_flash(:info, "Challenge set alias updated successfully.")
        |> redirect(to: challenge_set_alias_path(conn, :show, challenge_set_alias))
      {:error, changeset} ->
        render(conn, "edit.html", challenge_set_alias: challenge_set_alias, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    challenge_set_alias = Repo.get!(ChallengeSetAlias, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(challenge_set_alias)

    conn
    |> put_flash(:info, "Challenge set alias deleted successfully.")
    |> redirect(to: challenge_set_alias_path(conn, :index))
  end
end
