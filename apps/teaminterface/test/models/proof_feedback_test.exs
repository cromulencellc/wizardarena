defmodule Teaminterface.ProofFeedbackTest do
  use Teaminterface.ModelCase

  alias Teaminterface.ProofFeedback

  @valid_attrs %{error: "some content", signal: 42, successful: true, throw: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ProofFeedback.changeset(%ProofFeedback{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ProofFeedback.changeset(%ProofFeedback{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "loads previous-round feedbacks from ancient-round proofs" do
    [ancient_round, previous_round] = (1..2)
    |> Enum.map(fn(_n) ->
      build(:round) |> make_over |> insert
    end)

    _current_round = build(:round) |> make_current |> insert

    proof = insert(:proof, round: ancient_round)

    feedback = insert(:proof_feedback,
                      proof: proof,
                      round: previous_round)

    [found] = ProofFeedback.for_team_in_round(proof.team_id,
                                              previous_round.id)

    assert feedback.id == found.id
    assert proof.challenge_set_id == found.challenge_set.id
  end
end
