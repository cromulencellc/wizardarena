defmodule Teaminterface.EnablementTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Enablement

  @valid_attrs %{round_id: 1, challenge_set_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Enablement.changeset(%Enablement{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Enablement.changeset(%Enablement{}, @invalid_attrs)
    refute changeset.valid?
  end
end
