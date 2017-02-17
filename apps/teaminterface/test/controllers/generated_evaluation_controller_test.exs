defmodule Teaminterface.GeneratedEvaluationControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.Evaluation
  @valid_attrs %{connect: 42, memory: 42, success: 42, time: 42, timeout: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, evaluation_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing evaluations"
  end

  test "shows chosen resource", %{conn: conn} do
    evaluation = insert(:evaluation)
    conn = get conn, evaluation_path(conn, :show, evaluation)
    assert html_response(conn, 200) =~ "Show evaluation"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, evaluation_path(conn, :show, -1)
    end
  end
end
