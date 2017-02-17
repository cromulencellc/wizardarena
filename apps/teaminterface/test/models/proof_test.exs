defmodule Teaminterface.ProofTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Proof

  @valid_attrs %{digest: "some content",
                 throws: 5,
                 team_id: 1,
                 round_id: 1,
                 challenge_set_id: 1,
                 target_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Proof.changeset(%Proof{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Proof.changeset(%Proof{}, @invalid_attrs)
    refute changeset.valid?
  end
end
