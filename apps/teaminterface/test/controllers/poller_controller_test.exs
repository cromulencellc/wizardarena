defmodule Teaminterface.PollerControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.Poller
  @valid_attrs %{mean_cpu_clock: "120.5", mean_max_rss: "120.5", mean_min_flt: "120.5", mean_task_clock: "120.5", mean_utime: "120.5", mean_wall_time: "120.5", seed: "some content", stddev_cpu_clock: "120.5", stddev_max_rss: "120.5", stddev_min_flt: "120.5", stddev_task_clock: "120.5", stddev_utime: "120.5", stddev_wall_time: "120.5"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, poller_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing pollers"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, poller_path(conn, :new)
    assert html_response(conn, 200) =~ "New poller"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, poller_path(conn, :create), poller: @valid_attrs
    assert redirected_to(conn) == poller_path(conn, :index)
    assert Repo.get_by(Poller, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, poller_path(conn, :create), poller: @invalid_attrs
    assert html_response(conn, 200) =~ "New poller"
  end

  # test "shows chosen resource", %{conn: conn} do
  #   poller = Repo.insert! %Poller{}
  #   conn = get conn, poller_path(conn, :show, poller)
  #   assert html_response(conn, 200) =~ "Show poller"
  # end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, poller_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    poller = Repo.insert! %Poller{}
    conn = get conn, poller_path(conn, :edit, poller)
    assert html_response(conn, 200) =~ "Edit poller"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    poller = Repo.insert! %Poller{}
    conn = put conn, poller_path(conn, :update, poller), poller: @valid_attrs
    assert redirected_to(conn) == poller_path(conn, :show, poller)
    assert Repo.get_by(Poller, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    poller = Repo.insert! %Poller{}
    conn = put conn, poller_path(conn, :update, poller), poller: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit poller"
  end

  test "deletes chosen resource", %{conn: conn} do
    poller = Repo.insert! %Poller{}
    conn = delete conn, poller_path(conn, :delete, poller)
    assert redirected_to(conn) == poller_path(conn, :index)
    refute Repo.get(Poller, poller.id)
  end
end
