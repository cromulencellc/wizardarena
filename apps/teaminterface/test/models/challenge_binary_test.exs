defmodule Teaminterface.ChallengeBinaryTest do
  use Teaminterface.ModelCase

  alias Teaminterface.ChallengeBinary

  @valid_attrs %{index: 42, size: 42, patched_size: 42, challenge_set_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ChallengeBinary.changeset(%ChallengeBinary{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ChallengeBinary.changeset(%ChallengeBinary{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "find zero-indexed cb" do
    cb = insert(:challenge_binary, index: 0)
    n = cb.challenge_set.shortname

    assert cb.id == ChallengeBinary.find_by_filename(n).id
  end

  test "find nonzero-indexed cb" do
    cset = insert(:challenge_set)
    cbs = (1..3)
    |> Enum.map(&insert(:challenge_binary, index: &1, challenge_set: cset))

    cbs |> Enum.each(fn(cb) ->
      n = "#{cb.challenge_set.shortname}_#{cb.index}"
      assert cb.id == ChallengeBinary.find_by_filename(n).id
    end)
  end
end
