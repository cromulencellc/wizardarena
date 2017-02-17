defmodule Teaminterface.CrashTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Crash

  @valid_attrs %{signal: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Crash.changeset(%Crash{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Crash.changeset(%Crash{}, @invalid_attrs)
    refute changeset.valid?
  end
end
