defmodule Teaminterface.PollerTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Poller

  @valid_attrs %{mean_cpu_clock: "120.5", mean_max_rss: "120.5", mean_min_flt: "120.5", mean_task_clock: "120.5", mean_utime: "120.5", mean_wall_time: "120.5", seed: "some content", stddev_cpu_clock: "120.5", stddev_max_rss: "120.5", stddev_min_flt: "120.5", stddev_task_clock: "120.5", stddev_utime: "120.5", stddev_wall_time: "120.5"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Poller.changeset(%Poller{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Poller.changeset(%Poller{}, @invalid_attrs)
    refute changeset.valid?
  end
end
