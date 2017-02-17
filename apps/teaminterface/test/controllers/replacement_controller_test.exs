defmodule Teaminterface.ReplacementControllerTest do
  use Teaminterface.ConnCase

  @valid_attrs %{digest: "some content",
                 team_id: 1,
                 round_id: 1,
                 challenge_binary_id: 1}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, replacement_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing replacements"
  end

  test "shows chosen resource", %{conn: conn} do
    replacement = insert(:replacement)
    conn = get conn, replacement_path(conn, :show, replacement)
    assert html_response(conn, 200) =~ "Show replacement"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, replacement_path(conn, :show, -1)
    end
  end
end
