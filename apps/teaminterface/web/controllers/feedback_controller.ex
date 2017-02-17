defmodule Teaminterface.FeedbackController do
  use Teaminterface.Web, :controller

  alias Teaminterface.Crash
  alias Teaminterface.PollFeedback
  alias Teaminterface.ProofFeedback

  def cb(conn, _params = %{"round_id" => round_id}) do
    crashes = conn.assigns[:authed_team]
    |> Crash.for_team_in_round(round_id)
    |> Enum.map(&Crash.as_feedback_json/1)

    json conn, %{"cb" => crashes}
  end

  def pov(conn, _params = %{"round_id" => round_id}) do
    feedbacks = conn.assigns[:authed_team]
    |> ProofFeedback.for_team_in_round(round_id)
    |> Enum.map(&ProofFeedback.as_feedback_json/1)

    json conn, %{pov: feedbacks}
  end

  def poll(conn, _params = %{"round_id" => round_id}) do
    team = conn.assigns[:authed_team]

    polls = PollFeedback.aggregate_feedback_statuses(team.id,
                                                     round_id)

    json conn, %{poll: polls}
  end
end
