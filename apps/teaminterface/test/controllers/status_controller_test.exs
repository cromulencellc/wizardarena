defmodule Teaminterface.StatusControllerTest do
  use Teaminterface.ConnCase

  setup(%{team: my_team}) do
    ranked_teams = (1..5)
    |> Enum.map(&insert(:team,
                        score: &1 * 1.0))

    teams = [my_team | ranked_teams]

    {:ok,
     teams: teams}
  end

  test("get scores",
       %{conn: conn,
         teams: teams}) do
    current_round = insert(:round)

    resp = conn
    |> get("/status")
    |> json_response(200)

    assert resp["round"] == current_round.id
    scores = resp["scores"]

    score_expectations = teams
    |> Enum.sort_by(&Map.get(&1, :score), &>=/2)
    |> Enum.with_index()
    |> Enum.map(fn({team, place}) ->
      %{"score" => ((team.score * 100) |> Float.round |> trunc),
        "team" => team.id,
        "place" => place + 1,
        "rank" => place + 1
       }
    end)
    |> Enum.reverse()

    assert scores == score_expectations
  end
end
