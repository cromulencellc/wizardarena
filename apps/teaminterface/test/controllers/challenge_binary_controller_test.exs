defmodule Teaminterface.ChallengeBinaryControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.ChallengeBinary
  @valid_attrs %{index: 42, size: 42, patched_size: 42}
  @invalid_attrs %{patched_size: nil}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, challenge_binary_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing challenge binaries"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, challenge_binary_path(conn, :new)
    assert html_response(conn, 200) =~ "New challenge binary"
  end

  # test "creates resource and redirects when data is valid", %{conn: conn} do
  #   conn = post conn, challenge_binary_path(conn, :create), challenge_binary: @valid_attrs
  #   assert redirected_to(conn) == challenge_binary_path(conn, :index)
  #   assert Repo.get_by(ChallengeBinary, @valid_attrs)
  # end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, challenge_binary_path(conn, :create), challenge_binary: @invalid_attrs
    assert html_response(conn, 200) =~ "New challenge binary"
  end

  test "shows chosen resource", %{conn: conn} do
    challenge_binary = insert(:challenge_binary)
    conn = get conn, challenge_binary_path(conn, :show, challenge_binary)
    assert html_response(conn, 200) =~ "Show challenge binary"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, challenge_binary_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    challenge_binary = insert(:challenge_binary)
    conn = get conn, challenge_binary_path(conn, :edit, challenge_binary)
    assert html_response(conn, 200) =~ "Edit challenge binary"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    challenge_binary = insert(:challenge_binary)
    conn = put conn, challenge_binary_path(conn, :update, challenge_binary), challenge_binary: @valid_attrs
    assert redirected_to(conn) == challenge_binary_path(conn, :show, challenge_binary)
    assert Repo.get_by(ChallengeBinary, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    challenge_binary = insert(:challenge_binary)
    conn = put conn, challenge_binary_path(conn, :update, challenge_binary), challenge_binary: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit challenge binary"
  end

  test "deletes chosen resource", %{conn: conn} do
    challenge_binary = insert(:challenge_binary)
    conn = delete conn, challenge_binary_path(conn, :delete, challenge_binary)
    assert redirected_to(conn) == challenge_binary_path(conn, :index)
    refute Repo.get(ChallengeBinary, challenge_binary.id)
  end
end
