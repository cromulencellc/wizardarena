defmodule Teaminterface.ChallengeSetAliasTest do
  use Teaminterface.ModelCase

  alias Teaminterface.ChallengeSetAlias

  @valid_attrs %{cgc_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ChallengeSetAlias.changeset(%ChallengeSetAlias{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ChallengeSetAlias.changeset(%ChallengeSetAlias{}, @invalid_attrs)
    refute changeset.valid?
  end
end
