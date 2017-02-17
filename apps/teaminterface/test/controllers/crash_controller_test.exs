defmodule Teaminterface.CrashControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.Crash

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, crash_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing crashes"
  end

  test "shows chosen resource", %{conn: conn} do
    crash = insert(:crash)
    conn = get conn, crash_path(conn, :show, crash)
    assert html_response(conn, 200) =~ "Show crash"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, crash_path(conn, :show, -1)
    end
  end
end
