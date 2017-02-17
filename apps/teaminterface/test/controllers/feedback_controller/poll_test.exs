defmodule Teaminterface.FeedbackController.PollTest do
  use Teaminterface.ConnCase

  setup do
    ancient_round = build(:round) |> make_over |> insert
    previous_round = build(:round) |> make_over |> insert
    current_round = build(:round) |> make_current |> insert

    challenge_binary = insert(:challenge_binary)

    pollers = (1..2)
    |> Enum.map(&insert(:poller,
                        mean_wall_time: &1 * 1.0,
                        round: previous_round,
                        challenge_set: challenge_binary.challenge_set))

    {:ok,
     ancient_round: ancient_round,
     previous_round: previous_round,
     current_round: current_round,

     challenge_binary: challenge_binary,
     pollers: pollers
    }
  end

  test("fetches empty poll feedback when none were run",
       %{conn: conn,
         previous_round: previous_round
        }) do

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert resp == %{"poll" => []}
  end

  test("fetches poll feedback for a single cset",
       %{conn: conn,
         previous_round: previous_round,
         team: team,
         pollers: pollers
        }) do

    feedbacks = pollers
    |> Enum.map(&insert(:poll_feedback,
                        wall_time: (&1).mean_wall_time,
                        team: team,
                        poller: &1))

    assert length(pollers) == length(feedbacks)

    resp = conn
    |> get(feedback_path(previous_round))
    |> json_response(200)

    assert %{"poll" => poll_feedbacks} = resp
    # assert length(pollers) == length(poll_feedbacks)

    feedbacks
    |> Enum.each(fn(fb) ->
      assert Enum.any?(poll_feedbacks, fn(p) ->
        match?(%{"csid" => _shortname,
                 "performance" => %{"time" => _times,
                                      "memory" => _mem},
                 "functionality" => %{"x" => _xs}},
               p)
      end)
    end)
  end

  test "fetches poll feedback for multiple csets"

  defp feedback_path(round) do
    "/round/#{round.id}/feedback/poll"
  end
end
