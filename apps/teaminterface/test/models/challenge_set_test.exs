defmodule Teaminterface.ChallengeSetTest do
  use Teaminterface.ModelCase

  alias Teaminterface.ChallengeSet

  @valid_attrs %{name: "some content", shortname: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ChallengeSet.changeset(%ChallengeSet{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ChallengeSet.changeset(%ChallengeSet{}, @invalid_attrs)
    refute changeset.valid?
  end
end
