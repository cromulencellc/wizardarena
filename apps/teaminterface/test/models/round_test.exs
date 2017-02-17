defmodule Teaminterface.RoundTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Round

  @valid_attrs %{finished_at: Timex.now, nickname: "some content", started_at: Timex.now}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Round.changeset(%Round{}, @valid_attrs)
    assert changeset.valid?
  end

  # test "changeset with invalid attributes" do
  #   changeset = Round.changeset(%Round{}, @invalid_attrs)
  #   refute changeset.valid?
  # end

  test "load current" do
    _previous_round = build(:round) |> make_over |> insert
    current_round = build(:round) |> make_current |> insert
    _future_round = insert(:round)

    assert current_round.id == Round.current().id
  end
end
