defmodule Teaminterface.FeedbackController.CbTest do
  use Teaminterface.ConnCase

  setup do
    ancient_round = build(:round) |> make_over |> insert
    previous_round = build(:round) |> make_over |> insert
    current_round = build(:round) |> make_current |> insert

    challenge_binary = insert(:challenge_binary)

    {:ok,
     ancient_round: ancient_round,
     previous_round: previous_round,
     current_round: current_round,
     challenge_binary: challenge_binary
    }
  end

  test("Fetches empty cb feedback list when none were run",
       %{
         conn: conn,
         previous_round: previous_round
       }) do

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert resp == %{"cb" => []}
  end

  test("Fetches cb feedback with multiple crashes",
       %{
         conn: conn,
         previous_round: previous_round,
         challenge_binary: challenge_binary,
         team: team
       }) do

    crashes = (1..3)
    |> Enum.map(&insert(:crash,
                        signal: &1,
                        team: team,
                        round: previous_round,
                        challenge_binary: challenge_binary))

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert %{"cb" => cbs} = resp

    assert length(cbs) == length(crashes)

    signals = cbs
    |> Enum.map(&Map.get(&1, "signal"))
    |> MapSet.new

    assert Enum.all?(crashes, fn(fb) ->
      MapSet.member?(signals, fb.signal)
    end)
  end

  test("fetches cb feedback from multiple cbs in one cset",
       %{
         conn: conn,
         previous_round: previous_round,
         team: team
       }) do
    cset = insert(:challenge_set)

    binaries = (1..3)
    |> Enum.map(&insert(:challenge_binary,
                        challenge_set: cset,
                        index: &1))

    crashes = binaries
    |> Enum.map(&insert(:crash,
                        signal: 1,
                        team: team,
                        round: previous_round,
                        challenge_binary: &1))

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert %{"cb" => cbs} = resp

    assert length(cbs) == length(crashes)

    got_cbids = cbs
    |> Enum.map(&Map.get(&1, "cbid"))
    |> MapSet.new

    expected_cbids = binaries
    |> Enum.map(&Teaminterface.ChallengeBinary.cbid/1)

    assert Enum.all?(expected_cbids, &(MapSet.member?(got_cbids, &1)))
  end

  test "fetches cb feedback from multiple csets"

  defp feedback_path(round) do
    "/round/#{round.id}/feedback/cb"
  end
end
