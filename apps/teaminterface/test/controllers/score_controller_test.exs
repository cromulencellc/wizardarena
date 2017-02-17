defmodule Teaminterface.ScoreControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.Score
  @valid_attrs %{availability: "120.5", evaluation: "120.5", security: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, score_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing scores"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, score_path(conn, :new)
    assert html_response(conn, 200) =~ "New score"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, score_path(conn, :create), score: @valid_attrs
    assert redirected_to(conn) == score_path(conn, :index)
    assert Repo.get_by(Score, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, score_path(conn, :create), score: @invalid_attrs
    assert html_response(conn, 200) =~ "New score"
  end

  test "shows chosen resource", %{conn: conn} do
    score = Repo.insert! %Score{}
    conn = get conn, score_path(conn, :show, score)
    assert html_response(conn, 200) =~ "Show score"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, score_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    score = Repo.insert! %Score{}
    conn = get conn, score_path(conn, :edit, score)
    assert html_response(conn, 200) =~ "Edit score"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    score = Repo.insert! %Score{}
    conn = put conn, score_path(conn, :update, score), score: @valid_attrs
    assert redirected_to(conn) == score_path(conn, :show, score)
    assert Repo.get_by(Score, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    score = Repo.insert! %Score{}
    conn = put conn, score_path(conn, :update, score), score: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit score"
  end

  test "deletes chosen resource", %{conn: conn} do
    score = Repo.insert! %Score{}
    conn = delete conn, score_path(conn, :delete, score)
    assert redirected_to(conn) == score_path(conn, :index)
    refute Repo.get(Score, score.id)
  end
end
