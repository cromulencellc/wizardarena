defmodule Teaminterface.DownloadController.DownloadIdsTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  setup do
    ancient_round = build(:round) |> make_over |> insert
    previous_round = build(:round) |> make_over |> insert
    current_round = build(:round) |> make_current |> insert

    {:ok,
     ancient_round: ancient_round,
     previous_round: previous_round,
     current_round: current_round,
     opponent: insert(:team)
    }
  end

  test('not download current-round-submitted ids',
       %{conn: conn,
         current_round: current_round,
         opponent: opponent
        }) do
    firewall = insert(:firewall,
                      team: opponent,
                      round: current_round)
    |> create_file

    _enablement = insert(:enablement,
                         challenge_set: firewall.challenge_set,
                         round: current_round)

    path = dl_path(opponent, firewall)

    resp = conn
    |> get(path)
    |> response(404)

    assert resp
  end

  test('download an ids',
       %{
         conn: conn,
         previous_round: previous_round,
         opponent: opponent
       }) do
    firewall = insert(:firewall,
                      team: opponent,
                      round: previous_round)
    |> create_file

    _enablement = insert(:enablement,
                        challenge_set: firewall.challenge_set,
                        round: previous_round)

    path = dl_path(opponent, firewall)

    resp = conn
    |> get(path)
    |> response(200)

    assert resp
  end

  test('download stale ids rule after replacement',
       %{conn: conn,
         previous_round: previous_round,
         ancient_round: ancient_round,
         opponent: opponent
        }) do
    ancient_firewall = insert(:firewall,
                              team: opponent,
                              round: ancient_round)
    |> create_file

    _previous_firewall = insert(:firewall,
                              team: opponent,
                              round: previous_round,
                              challenge_set: ancient_firewall.challenge_set)
    |> create_file

    _enablements = [ancient_round, previous_round]
    |> Enum.map(&insert(:enablement,
                        challenge_set: ancient_firewall.challenge_set,
                        round: &1))

    path = dl_path(opponent, ancient_firewall)

    resp = conn
    |> get(path)
    |> response(200)

    assert resp
  end

  test 'download hot ids rule'

  test 'download pending ids rule'

  defp dl_path(opponent, firewall) do
    "/dl/~B/ids/~s_~s_~B.ids"
    |> :io_lib.format([opponent.id,
                       firewall.challenge_set.shortname,
                       firewall.digest,
                       firewall.inserted_at |> DateTime.to_unix
                      ])
  |> IO.chardata_to_string
  end

  defp create_file(firewall) do
    dest_path = "~s/rounds/~B/~B/ids/~B.ids"
    |> :io_lib.format([Application.get_env(:teaminterface, :download_root),
                       firewall.round_id,
                       firewall.team_id,
                       firewall.challenge_set_id])
    src_path = fixture_path 'LUNGE_00002.rules'

    :ok = dest_path |> Path.dirname |> File.mkdir_p
    :ok = File.cp src_path, dest_path

    firewall
  end
end
