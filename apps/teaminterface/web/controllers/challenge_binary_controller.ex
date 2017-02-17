defmodule Teaminterface.ChallengeBinaryController do
  use Teaminterface.Web, :controller

  alias Teaminterface.ChallengeBinary

  plug :scrub_params, "challenge_binary" when action in [:create, :update]

  def index(conn, _params) do
    challenge_binaries = Repo.all(ChallengeBinary)
    render(conn, "index.html", challenge_binaries: challenge_binaries)
  end

  def new(conn, _params) do
    changeset = ChallengeBinary.changeset(%ChallengeBinary{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"challenge_binary" => challenge_binary_params}) do
    changeset = ChallengeBinary.changeset(%ChallengeBinary{}, challenge_binary_params)

    case Repo.insert(changeset) do
      {:ok, _challenge_binary} ->
        conn
        |> put_flash(:info, "Challenge binary created successfully.")
        |> redirect(to: challenge_binary_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    challenge_binary = Repo.get!(ChallengeBinary, id)
    render(conn, "show.html", challenge_binary: challenge_binary)
  end

  def edit(conn, %{"id" => id}) do
    challenge_binary = Repo.get!(ChallengeBinary, id)
    changeset = ChallengeBinary.changeset(challenge_binary)
    render(conn, "edit.html", challenge_binary: challenge_binary, changeset: changeset)
  end

  def update(conn, %{"id" => id, "challenge_binary" => challenge_binary_params}) do
    challenge_binary = Repo.get!(ChallengeBinary, id)
    changeset = ChallengeBinary.changeset(challenge_binary, challenge_binary_params)

    case Repo.update(changeset) do
      {:ok, challenge_binary} ->
        conn
        |> put_flash(:info, "Challenge binary updated successfully.")
        |> redirect(to: challenge_binary_path(conn, :show, challenge_binary))
      {:error, changeset} ->
        render(conn, "edit.html", challenge_binary: challenge_binary, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    challenge_binary = Repo.get!(ChallengeBinary, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(challenge_binary)

    conn
    |> put_flash(:info, "Challenge binary deleted successfully.")
    |> redirect(to: challenge_binary_path(conn, :index))
  end
end
