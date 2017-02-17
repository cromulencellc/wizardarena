defmodule Teaminterface.FirewallTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Firewall

  @valid_attrs %{digest: "some content",
                 team_id: 1,
                 round_id: 1,
                 challenge_set_id: 1,
                 scoot: false}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Firewall.changeset(%Firewall{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Firewall.changeset(%Firewall{}, @invalid_attrs)
    refute changeset.valid?
  end
end
