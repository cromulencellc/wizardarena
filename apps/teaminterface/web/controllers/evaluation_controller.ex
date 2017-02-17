defmodule Teaminterface.EvaluationController do
  use Teaminterface.Web, :controller

  alias Teaminterface.Replacement
  alias Teaminterface.Firewall

  def cb(conn, params = %{
        "round_id" => round_id,
        "team_id" => opponent_id
      }) do
    replacements = Replacement.from_team_in_round(
      String.to_integer(opponent_id),
      String.to_integer(round_id))

    json_replacements = replacements
    |> Enum.map(fn(replacement) ->
      full_replacement_filename = "~s_~s_~B"
      |> :io_lib.format([Replacement.filename(replacement),
                         replacement.digest,
                         replacement.inserted_at |> DateTime.to_unix])
      |> IO.chardata_to_string

      %{"cbid" => Replacement.filename(replacement),
        "csid" => (replacement.challenge_set.id |> Integer.to_string),
        "hash" => replacement.digest,
        "uri" => download_cb_path(conn,
                                  :cb,
                                  opponent_id,
                                  full_replacement_filename)}
    end)

    json conn, %{"cb" => json_replacements}
  end

  def ids(conn, params = %{
        "round_id" => round_id,
        "team_id" => opponent_id
      }) do
    firewalls = Firewall.from_team_in_round(
      String.to_integer(opponent_id),
      String.to_integer(round_id))

    json_firewalls = firewalls
    |> Enum.map(fn(firewall) ->
      full_firewall_filename = "~s_~s_~B"
      |> :io_lib.format([firewall.challenge_set.shortname,
                         firewall.digest,
                         firewall.inserted_at |> DateTime.to_unix])
      |> IO.chardata_to_string

      %{"csid" => (firewall.challenge_set.id |> Integer.to_string),
        "hash" => firewall.digest,
        "uri" => download_ids_path(conn,
                                   :ids,
                                   opponent_id,
                                   full_firewall_filename)}
    end)

    json conn, %{"ids" => json_firewalls}
  end
end
