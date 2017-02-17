defmodule Teaminterface.GeneratedEvaluationController do
  use Teaminterface.Web, :controller

  alias Teaminterface.Evaluation

  plug :scrub_params, "evaluation" when action in [:create, :update]

  def index(conn, _params) do
    evaluations = Repo.all(Evaluation)
    render(conn, "index.html", evaluations: evaluations)
  end

  def new(conn, _params) do
    changeset = Evaluation.changeset(%Evaluation{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"evaluation" => evaluation_params}) do
    changeset = Evaluation.changeset(%Evaluation{}, evaluation_params)

    case Repo.insert(changeset) do
      {:ok, _evaluation} ->
        conn
        |> put_flash(:info, "Evaluation created successfully.")
        |> redirect(to: evaluation_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    evaluation = Repo.get!(Evaluation, id)
    render(conn, "show.html", evaluation: evaluation)
  end

  def edit(conn, %{"id" => id}) do
    evaluation = Repo.get!(Evaluation, id)
    changeset = Evaluation.changeset(evaluation)
    render(conn, "edit.html", evaluation: evaluation, changeset: changeset)
  end

  def update(conn, %{"id" => id, "evaluation" => evaluation_params}) do
    evaluation = Repo.get!(Evaluation, id)
    changeset = Evaluation.changeset(evaluation, evaluation_params)

    case Repo.update(changeset) do
      {:ok, evaluation} ->
        conn
        |> put_flash(:info, "Evaluation updated successfully.")
        |> redirect(to: evaluation_path(conn, :show, evaluation))
      {:error, changeset} ->
        render(conn, "edit.html", evaluation: evaluation, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    evaluation = Repo.get!(Evaluation, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(evaluation)

    conn
    |> put_flash(:info, "Evaluation deleted successfully.")
    |> redirect(to: evaluation_path(conn, :index))
  end
end
