defmodule Teaminterface.PollFeedbackControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.PollFeedback
  @valid_attrs %{cpu_clock: 42, max_rss: 42, min_flt: 42, status: "some content", task_clock: 42, utime: "120.5", wall_time: "120.5"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, poll_feedback_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing poll feedbacks"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, poll_feedback_path(conn, :new)
    assert html_response(conn, 200) =~ "New poll feedback"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, poll_feedback_path(conn, :create), poll_feedback: @valid_attrs
    assert redirected_to(conn) == poll_feedback_path(conn, :index)
    assert Repo.get_by(PollFeedback, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, poll_feedback_path(conn, :create), poll_feedback: @invalid_attrs
    assert html_response(conn, 200) =~ "New poll feedback"
  end

  test "shows chosen resource", %{conn: conn} do
    poll_feedback = Repo.insert! %PollFeedback{}
    conn = get conn, poll_feedback_path(conn, :show, poll_feedback)
    assert html_response(conn, 200) =~ "Show poll feedback"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, poll_feedback_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    poll_feedback = Repo.insert! %PollFeedback{}
    conn = get conn, poll_feedback_path(conn, :edit, poll_feedback)
    assert html_response(conn, 200) =~ "Edit poll feedback"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    poll_feedback = Repo.insert! %PollFeedback{}
    conn = put conn, poll_feedback_path(conn, :update, poll_feedback), poll_feedback: @valid_attrs
    assert redirected_to(conn) == poll_feedback_path(conn, :show, poll_feedback)
    assert Repo.get_by(PollFeedback, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    poll_feedback = Repo.insert! %PollFeedback{}
    conn = put conn, poll_feedback_path(conn, :update, poll_feedback), poll_feedback: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit poll feedback"
  end

  test "deletes chosen resource", %{conn: conn} do
    poll_feedback = Repo.insert! %PollFeedback{}
    conn = delete conn, poll_feedback_path(conn, :delete, poll_feedback)
    assert redirected_to(conn) == poll_feedback_path(conn, :index)
    refute Repo.get(PollFeedback, poll_feedback.id)
  end
end
