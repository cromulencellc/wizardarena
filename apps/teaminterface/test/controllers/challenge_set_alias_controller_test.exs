defmodule Teaminterface.ChallengeSetAliasControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.ChallengeSetAlias
  @valid_attrs %{cgc_id: 42}
  @invalid_attrs %{cgc_id: nil}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, challenge_set_alias_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing challenge set aliases"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, challenge_set_alias_path(conn, :new)
    assert html_response(conn, 200) =~ "New challenge set alias"
  end

  # test "creates resource and redirects when data is valid", %{conn: conn} do
  #   conn = post conn, challenge_set_alias_path(conn, :create), challenge_set_alias: @valid_attrs
  #   assert redirected_to(conn) == challenge_set_alias_path(conn, :index)
  #   assert Repo.get_by(ChallengeSetAlias, @valid_attrs)
  # end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, challenge_set_alias_path(conn, :create), challenge_set_alias: @invalid_attrs
    assert html_response(conn, 200) =~ "New challenge set alias"
  end

  test "shows chosen resource", %{conn: conn} do
    challenge_set_alias = insert(:challenge_set_alias)
    conn = get conn, challenge_set_alias_path(conn, :show, challenge_set_alias)
    assert html_response(conn, 200) =~ "Show challenge set alias"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, challenge_set_alias_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    challenge_set_alias = insert(:challenge_set_alias)
    conn = get conn, challenge_set_alias_path(conn, :edit, challenge_set_alias)
    assert html_response(conn, 200) =~ "Edit challenge set alias"
  end

  # test "updates chosen resource and redirects when data is valid", %{conn: conn} do
  #   challenge_set_alias = insert(:challenge_set_alias)

  #   conn = put conn, challenge_set_alias_path(conn, :update, challenge_set_alias), challenge_set_alias: @valid_attrs
  #   assert redirected_to(conn) == challenge_set_alias_path(conn, :show, challenge_set_alias)
  #   assert Repo.get_by(ChallengeSetAlias, @valid_attrs)
  # end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    challenge_set_alias = insert(:challenge_set_alias)
    conn = put conn, challenge_set_alias_path(conn, :update, challenge_set_alias), challenge_set_alias: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit challenge set alias"
  end

  test "deletes chosen resource", %{conn: conn} do
    challenge_set_alias = insert(:challenge_set_alias)
    conn = delete conn, challenge_set_alias_path(conn, :delete, challenge_set_alias)
    assert redirected_to(conn) == challenge_set_alias_path(conn, :index)
    refute Repo.get(ChallengeSetAlias, challenge_set_alias.id)
  end
end
