defmodule Teaminterface.PollFeedbackTest do
  use Teaminterface.ModelCase

  alias Teaminterface.PollFeedback

  @valid_attrs %{cpu_clock: 42, max_rss: 42, min_flt: 42, status: "some content", task_clock: 42, utime: "120.5", wall_time: "120.5"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PollFeedback.changeset(%PollFeedback{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PollFeedback.changeset(%PollFeedback{}, @invalid_attrs)
    refute changeset.valid?
  end
end
