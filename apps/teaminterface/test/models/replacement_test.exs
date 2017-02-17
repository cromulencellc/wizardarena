defmodule Teaminterface.ReplacementTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Replacement

  @valid_attrs %{digest: "some content",
                 team_id: 1,
                 round_id: 1,
                 challenge_binary_id: 1,
                 size: 1,
                 scoot: false}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Replacement.changeset(%Replacement{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Replacement.changeset(%Replacement{}, @invalid_attrs)
    refute changeset.valid?
  end
end
