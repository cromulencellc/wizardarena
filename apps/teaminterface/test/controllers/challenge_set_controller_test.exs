defmodule Teaminterface.ChallengeSetControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.ChallengeSet
  @valid_attrs %{name: "some content", shortname: "some content"}
  @invalid_attrs %{name: nil, shortname: nil}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, challenge_set_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing challenge sets"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, challenge_set_path(conn, :new)
    assert html_response(conn, 200) =~ "New challenge set"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, challenge_set_path(conn, :create), challenge_set: @valid_attrs
    assert redirected_to(conn) == challenge_set_path(conn, :index)
    assert Repo.get_by(ChallengeSet, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, challenge_set_path(conn, :create), challenge_set: @invalid_attrs
    assert html_response(conn, 200) =~ "New challenge set"
  end

  test "shows chosen resource", %{conn: conn} do
    challenge_set = Repo.insert! %ChallengeSet{name: "example",
                                              shortname: "example"}
    conn = get conn, challenge_set_path(conn, :show, challenge_set)
    assert html_response(conn, 200) =~ "Show challenge set"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, challenge_set_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    challenge_set = Repo.insert! %ChallengeSet{name: "example",
                                              shortname: "example"}
    conn = get conn, challenge_set_path(conn, :edit, challenge_set)
    assert html_response(conn, 200) =~ "Edit challenge set"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    challenge_set = Repo.insert! %ChallengeSet{name: "example",
                                               shortname: "example"}
    conn = put conn, challenge_set_path(conn, :update, challenge_set), challenge_set: @valid_attrs
    assert redirected_to(conn) == challenge_set_path(conn, :show, challenge_set)
    assert Repo.get_by(ChallengeSet, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    challenge_set = Repo.insert! %ChallengeSet{name: "example",
                                              shortname: "example"}
    conn = put conn, challenge_set_path(conn, :update, challenge_set), challenge_set: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit challenge set"
  end

  test "deletes chosen resource", %{conn: conn} do
    challenge_set = Repo.insert! %ChallengeSet{name: "example",
                                              shortname: "example"}
    conn = delete conn, challenge_set_path(conn, :delete, challenge_set)
    assert redirected_to(conn) == challenge_set_path(conn, :index)
    refute Repo.get(ChallengeSet, challenge_set.id)
  end
end
