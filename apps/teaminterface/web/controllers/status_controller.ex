defmodule Teaminterface.StatusController do
  use Teaminterface.Web, :controller

  alias Teaminterface.Round
  alias Teaminterface.Team

  def index(conn, _params) do
    round = Round.current_or_next
    scores = Team.scoreboard

    json conn, %{round: round.id,
                 scores: scores}
  end
end
