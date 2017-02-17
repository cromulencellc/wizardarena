defmodule Teaminterface.ScoreTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Score

  @valid_attrs %{availability: "120.5", evaluation: "120.5", security: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Score.changeset(%Score{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Score.changeset(%Score{}, @invalid_attrs)
    refute changeset.valid?
  end
end
