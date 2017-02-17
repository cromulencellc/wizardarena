defmodule Teaminterface.FirewallControllerTest do
  use Teaminterface.ConnCase

  @valid_attrs %{digest: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, firewall_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing firewalls"
  end

  test "shows chosen resource", %{conn: conn} do
    firewall = insert(:firewall)
    conn = get conn, firewall_path(conn, :show, firewall)
    assert html_response(conn, 200) =~ "Show firewall"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, firewall_path(conn, :show, -1)
    end
  end
end
