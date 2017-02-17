defmodule Teaminterface.RoundControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.Round
  @valid_attrs %{finished_at: "2010-04-17 14:00:00", nickname: "some content", started_at: "2010-04-17 14:00:00", seed: "asdf", secret: "asdf"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, round_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing rounds"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, round_path(conn, :new)
    assert html_response(conn, 200) =~ "New round"
  end

  # test "creates resource and redirects when data is valid", %{conn: conn} do
  #   conn = post conn, round_path(conn, :create), round: @valid_attrs
  #   assert redirected_to(conn) == round_path(conn, :index)
  #   assert Repo.get_by(Round, @valid_attrs)
  # end

  # test "does not create resource and renders errors when data is invalid", %{conn: conn} do
  #   conn = post conn, round_path(conn, :create), round: @invalid_attrs
  #   assert html_response(conn, 200) =~ "New round"
  # end

  test "shows chosen resource", %{conn: conn} do
    round = insert(:round)
    conn = get conn, round_path(conn, :show, round)
    assert html_response(conn, 200) =~ "Show round"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, round_path(conn, :show, -1)
    end
  end

  # test "renders form for editing chosen resource", %{conn: conn} do
  #   round = insert(:round)
  #   conn = get conn, round_path(conn, :edit, round)
  #   assert html_response(conn, 200) =~ "Edit round"
  # end

  # test "updates chosen resource and redirects when data is valid", %{conn: conn} do
  #   round = insert(:round)
  #   conn = put conn, round_path(conn, :update, round), round: @valid_attrs
  #   assert redirected_to(conn) == round_path(conn, :show, round)
  #   assert Repo.get_by(Round, @valid_attrs)
  # end

  # test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
  #   round = insert(:round)
  #   conn = put conn, round_path(conn, :update, round), round: @invalid_attrs
  #   assert html_response(conn, 200) =~ "Edit round"
  # end

  # test "deletes chosen resource", %{conn: conn} do
  #   round = insert(:round)
  #   conn = delete conn, round_path(conn, :delete, round)
  #   assert redirected_to(conn) == round_path(conn, :index)
  #   refute Repo.get(Round, round.id)
  # end
end
