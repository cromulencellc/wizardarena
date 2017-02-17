defmodule Teaminterface.TeamTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Team

  @valid_attrs %{color: "some content",
                 displayname: "some content",
                 name: "some content",
                 shortname: "some content",
                 score: 31337.0,
                 password_digest:
                 "$2b$04$UAxma4sWhbqg3XOA2AUrj.YfZLVul4JXOR3Vn4f7qcdC.xR8jZFAK"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Team.changeset(%Team{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Team.changeset(%Team{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "creates password change changeset" do
    initial = insert(:team)
    changeset = Team.update_password(initial, "test password")
    assert changeset.valid?
    Teaminterface.Repo.update changeset
    updated = Teaminterface.Repo.get Team, initial.id
    refute initial.password_digest == updated.password_digest
  end
end
