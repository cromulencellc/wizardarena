defmodule Teaminterface.DownloadController.DownloadCbTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  alias Teaminterface.Replacement

  setup do
    ancient_round = build(:round) |> make_over |> insert
    previous_round = build(:round) |> make_over |> insert
    current_round = build(:round) |> make_current |> insert

    challenge_binary = insert(:challenge_binary)

    {:ok,
     ancient_round: ancient_round,
     previous_round: previous_round,
     current_round: current_round,
     challenge_binary: challenge_binary,
     opponent: insert(:team)
    }
  end

  test('not download current-round-submitted challenge binary',
    %{conn: conn,
      current_round: current_round,
      challenge_binary: challenge_binary,
      opponent: opponent
    }) do
    replacement = insert(:replacement,
                         team: opponent,
                         round: current_round,
                         challenge_binary: challenge_binary)
    |> create_file

    _enablement = insert(:enablement,
                         challenge_set: challenge_binary.challenge_set,
                         round: current_round)

    path = dl_path(opponent, replacement)

    resp = conn
    |> get(path)
    |> response(404)

    assert resp
  end

  test('download hot cb',
       %{
         conn: conn,
         previous_round: previous_round,
         challenge_binary: challenge_binary,
         opponent: opponent,
       }) do
    replacement = insert(:replacement,
                         team: opponent,
                         round: previous_round,
                         challenge_binary: challenge_binary)
    |> create_file

    _enablement = insert(:enablement,
                        challenge_set: challenge_binary.challenge_set,
                        round: previous_round)

    path = dl_path(opponent, replacement)

    resp = conn
    |> get(path)
    |> response(200)

    assert resp
  end

  # round zero
  test 'download original challenge binary'

  # round n-3
  test('download stale challenge binary',
    %{
      conn: conn,
      ancient_round: ancient_round,
      challenge_binary: challenge_binary,
      opponent: opponent
    }) do
    replacement = insert(:replacement,
                         team: opponent,
                         round: ancient_round,
                         challenge_binary: challenge_binary)
    |> create_file

    _enablement = insert(:enablement,
                         challenge_set: challenge_binary.challenge_set,
                         round: ancient_round)

    path = dl_path(opponent, replacement)

    resp = conn
    |> get(path)
    |> response(200)

    assert resp
  end

  # serve n-3 when n is available
  test('download stale challenge binary after replacement',
    %{
      conn: conn,
      ancient_round: ancient_round,
      previous_round: previous_round,
      challenge_binary: challenge_binary,
      opponent: opponent
    }) do
    ancient_replacement = insert(:replacement,
                                 team: opponent,
                                 round: ancient_round,
                                 challenge_binary: challenge_binary)
    |> create_file

    _previous_replacement = insert(:replacement,
      team: opponent,
      round: previous_round,
      challenge_binary: challenge_binary)
    |> create_file('LUNGE_00001_modified.cgc')

    _enablement = insert(:enablement,
                         challenge_set: challenge_binary.challenge_set,
                         round: ancient_round)

    path = dl_path(opponent, ancient_replacement)

    resp = conn
    |> get(path)
    |> response(200)

    assert resp
  end

  defp dl_path(opponent, replacement) do
    "/dl/~B/cb/~s_~s_~B"
    |> :io_lib.format([opponent.id,
                       Replacement.filename(replacement),
                       replacement.digest,
                       replacement.inserted_at |> DateTime.to_unix
                      ])
  |> IO.chardata_to_string
  end

  defp create_file(replacement, filename \\ 'LUNGE_00001.cgc') do
    dest_path = "~s/rounds/~B/~B/rcb/~s"
    |> :io_lib.format([Application.get_env(:teaminterface, :download_root),
                       replacement.round_id,
                       replacement.team_id,
                       Replacement.filename(replacement)])
    src_path = fixture_path filename

    :ok = dest_path |> Path.dirname |> File.mkdir_p
    :ok = File.cp src_path, dest_path

    replacement
  end
end
