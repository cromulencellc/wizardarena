defmodule Teaminterface.ProofFeedbackControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.ProofFeedback
  @valid_attrs %{error: "some content", signal: 42, successful: true, throw: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, proof_feedback_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing proof feedbacks"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, proof_feedback_path(conn, :new)
    assert html_response(conn, 200) =~ "New proof feedback"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, proof_feedback_path(conn, :create), proof_feedback: @valid_attrs
    assert redirected_to(conn) == proof_feedback_path(conn, :index)
    assert Repo.get_by(ProofFeedback, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, proof_feedback_path(conn, :create), proof_feedback: @invalid_attrs
    assert html_response(conn, 200) =~ "New proof feedback"
  end

  test "shows chosen resource", %{conn: conn} do
    proof_feedback = Repo.insert! %ProofFeedback{}
    conn = get conn, proof_feedback_path(conn, :show, proof_feedback)
    assert html_response(conn, 200) =~ "Show proof feedback"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, proof_feedback_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    proof_feedback = Repo.insert! %ProofFeedback{}
    conn = get conn, proof_feedback_path(conn, :edit, proof_feedback)
    assert html_response(conn, 200) =~ "Edit proof feedback"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    proof_feedback = Repo.insert! %ProofFeedback{}
    conn = put conn, proof_feedback_path(conn, :update, proof_feedback), proof_feedback: @valid_attrs
    assert redirected_to(conn) == proof_feedback_path(conn, :show, proof_feedback)
    assert Repo.get_by(ProofFeedback, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    proof_feedback = Repo.insert! %ProofFeedback{}
    conn = put conn, proof_feedback_path(conn, :update, proof_feedback), proof_feedback: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit proof feedback"
  end

  test "deletes chosen resource", %{conn: conn} do
    proof_feedback = Repo.insert! %ProofFeedback{}
    conn = delete conn, proof_feedback_path(conn, :delete, proof_feedback)
    assert redirected_to(conn) == proof_feedback_path(conn, :index)
    refute Repo.get(ProofFeedback, proof_feedback.id)
  end
end
