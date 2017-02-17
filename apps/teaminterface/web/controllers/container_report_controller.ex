defmodule Teaminterface.ContainerReportController do
  use Teaminterface.Web, :controller

  alias Teaminterface.ContainerReport

  plug :scrub_params, "container_report" when action in [:create, :update]

  def index(conn, _params) do
    container_reports = Repo.all(ContainerReport)
    render(conn, "index.html", container_reports: container_reports)
  end

  def new(conn, _params) do
    changeset = ContainerReport.changeset(%ContainerReport{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"container_report" => container_report_params}) do
    changeset = ContainerReport.changeset(%ContainerReport{}, container_report_params)

    case Repo.insert(changeset) do
      {:ok, _container_report} ->
        conn
        |> put_flash(:info, "Container report created successfully.")
        |> redirect(to: container_report_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    container_report = Repo.get!(ContainerReport, id)
    render(conn, "show.html", container_report: container_report)
  end

  def edit(conn, %{"id" => id}) do
    container_report = Repo.get!(ContainerReport, id)
    changeset = ContainerReport.changeset(container_report)
    render(conn, "edit.html", container_report: container_report, changeset: changeset)
  end

  def update(conn, %{"id" => id, "container_report" => container_report_params}) do
    container_report = Repo.get!(ContainerReport, id)
    changeset = ContainerReport.changeset(container_report, container_report_params)

    case Repo.update(changeset) do
      {:ok, container_report} ->
        conn
        |> put_flash(:info, "Container report updated successfully.")
        |> redirect(to: container_report_path(conn, :show, container_report))
      {:error, changeset} ->
        render(conn, "edit.html", container_report: container_report, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    container_report = Repo.get!(ContainerReport, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(container_report)

    conn
    |> put_flash(:info, "Container report deleted successfully.")
    |> redirect(to: container_report_path(conn, :index))
  end
end
