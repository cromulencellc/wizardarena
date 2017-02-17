defmodule Teaminterface.FeedbackController.ProofTest do
  use Teaminterface.ConnCase

  setup do
    ancient_round = build(:round) |> make_over |> insert
    previous_round = build(:round) |> make_over |> insert
    current_round = build(:round) |> make_current |> insert

    victim = insert(:team)

    challenge_binary = insert(:challenge_binary)

    {:ok,
     ancient_round: ancient_round,
     previous_round: previous_round,
     current_round: current_round,

     victim: victim,

     challenge_binary: challenge_binary
    }
  end

  test("Fetches empty proof feedback list when none were run",
       %{
         conn: conn,
         previous_round: previous_round
       }) do


    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert resp == %{"pov" => []}
  end

  test("Fetches a single successful feedback after a single run",
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         team: team,
         victim: victim
       }) do
    proof = insert(:proof,
                   round: ancient_round,
                   team: team,
                   target: victim)
    _proof_feedback = insert(:proof_feedback,
                            proof: proof,
                            round: previous_round)

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert resp == %{
      "pov" => [
      %{"csid" => "#{proof.challenge_set.id}",
        "team" => victim.id,
        "throw" => 1,
        "result" => "success"
       }
    ]}
  end

  test("Fetches an erroneous feedback",
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         team: team,
         victim: victim
       }) do
    proof = insert(:proof,
                   round: ancient_round,
                   team: team,
                   target: victim)
    _proof_feedback = insert(:proof_feedback,
                            proof: proof,
                            round: previous_round,
                            successful: false,
                            error: "asdf")

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert resp == %{
      "pov" => [
      %{"csid" => "#{proof.challenge_set.id}",
        "team" => victim.id,
        "throw" => 1,
        "result" => "fail",
        "error" => "asdf"
       }
    ]}
  end

  test("Fetches multiple feedbacks after running a proof multiple times",
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         team: team,
         victim: victim
       }) do
    proof = insert(:proof,
                   round: ancient_round,
                   team: team,
                   target: victim)

    feedbacks = (1..3)
    |> Enum.map(&insert(:proof_feedback,
                        proof: proof,
                        round: previous_round,
                        throw: &1))

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert %{"pov" => povs} = resp

    assert length(povs) == length(feedbacks)
    pov_throws = povs
    |> Enum.map(&Map.get(&1, "throw"))
    |> MapSet.new

    assert Enum.all?(feedbacks, fn(fb) ->
      MapSet.member?(pov_throws, fb.throw)
    end)
  end

  test("Fetches multiple crashes against different teams",
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         team: team,
         victim: victim
       }) do
    other_victim = insert(:team)
    proofs = [victim, other_victim]
    |> Enum.map(&insert(:proof,
                        round: ancient_round,
                        team: team,
                        target: &1))

    feedbacks = proofs
    |> Enum.map(&insert(:proof_feedback,
                        proof: &1,
                        round: previous_round))

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert %{"pov" => povs} = resp

    assert length(povs) == length(feedbacks)
    pov_teams = povs
    |> Enum.map(&Map.get(&1, "team"))
    |> MapSet.new

    assert Enum.all?([victim, other_victim], fn(fb) ->
      MapSet.member?(pov_teams, fb.id)
    end)
  end

  defp feedback_path(round) do
    "/round/#{round.id}/feedback/pov"
  end
end
