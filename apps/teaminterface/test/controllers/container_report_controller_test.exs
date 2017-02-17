defmodule Teaminterface.ContainerReportControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.ContainerReport
  @valid_attrs %{last_complete_position: 42, max_position: 42, polls_failed: 42, polls_passed: 42, polls_timed_out: 42, polls_total: 42, replay_seed: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, container_report_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing container reports"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, container_report_path(conn, :new)
    assert html_response(conn, 200) =~ "New container report"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, container_report_path(conn, :create), container_report: @valid_attrs
    assert redirected_to(conn) == container_report_path(conn, :index)
    assert Repo.get_by(ContainerReport, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, container_report_path(conn, :create), container_report: @invalid_attrs
    assert html_response(conn, 200) =~ "New container report"
  end

  test "shows chosen resource", %{conn: conn} do
    container_report = Repo.insert! %ContainerReport{}
    conn = get conn, container_report_path(conn, :show, container_report)
    assert html_response(conn, 200) =~ "Show container report"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, container_report_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    container_report = Repo.insert! %ContainerReport{}
    conn = get conn, container_report_path(conn, :edit, container_report)
    assert html_response(conn, 200) =~ "Edit container report"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    container_report = Repo.insert! %ContainerReport{}
    conn = put conn, container_report_path(conn, :update, container_report), container_report: @valid_attrs
    assert redirected_to(conn) == container_report_path(conn, :show, container_report)
    assert Repo.get_by(ContainerReport, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    container_report = Repo.insert! %ContainerReport{}
    conn = put conn, container_report_path(conn, :update, container_report), container_report: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit container report"
  end

  test "deletes chosen resource", %{conn: conn} do
    container_report = Repo.insert! %ContainerReport{}
    conn = delete conn, container_report_path(conn, :delete, container_report)
    assert redirected_to(conn) == container_report_path(conn, :index)
    refute Repo.get(ContainerReport, container_report.id)
  end
end
