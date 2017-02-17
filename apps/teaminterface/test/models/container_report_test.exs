defmodule Teaminterface.ContainerReportTest do
  use Teaminterface.ModelCase

  alias Teaminterface.ContainerReport

  @valid_attrs %{last_complete_position: 42, max_position: 42, polls_failed: 42, polls_passed: 42, polls_timed_out: 42, polls_total: 42, replay_seed: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ContainerReport.changeset(%ContainerReport{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ContainerReport.changeset(%ContainerReport{}, @invalid_attrs)
    refute changeset.valid?
  end
end
