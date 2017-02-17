defmodule Teaminterface.EvaluationControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.Replacement

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

  test('get cb evaulation metadata from old round with only one enablement',
       %{
         conn: conn,
         previous_round: previous_round,
         opponent: opponent
       }) do
    challenge_binary = insert(:challenge_binary)
    replacement = insert(:replacement,
                         team: opponent,
                         round: previous_round,
                         challenge_binary: challenge_binary)
    enablement = insert(:enablement,
                        challenge_set: challenge_binary.challenge_set,
                        round: previous_round)

    evaluation_path = eval_path(previous_round,
                                "cb",
                                opponent)

    resp = conn
    |> get(evaluation_path)
    |> json_response(200)

    expected_dl_path = dl_path(opponent,
                               replacement,
                               "cb")

    assert resp ==
      %{"cb" => [
         %{"cbid" => Replacement.filename(replacement),
           "hash" => replacement.digest,
           "csid" => "#{challenge_binary.challenge_set.id}",
           "uri" => expected_dl_path
          }]}
  end

  test('get cb evaluation metadata from old round with multiple rcbs',
       %{
         conn: conn,
         previous_round: previous_round,
         opponent: opponent
       }) do
    enablement = insert(:enablement,
                        round: previous_round)

    cbs = (1..3)
    |> Enum.map(&insert(:challenge_binary,
                        challenge_set: enablement.challenge_set,
                        index: &1))

    cset_name = enablement.challenge_set.shortname

    replacements = cbs
    |> Enum.map(&insert(:replacement,
                        team: opponent,
                        round: previous_round,
                        challenge_binary: &1))

    evaluation_path = eval_path(previous_round,
                                "cb",
                                opponent)

    resp = conn
    |> get(evaluation_path)
    |> json_response(200)

    assert %{"cb" => cb_evals} = resp
    assert is_list(cb_evals)

    replacements
    |> Enum.each(fn(r) ->
      expect_dl = dl_path(opponent,
                          r,
                          "cb")

      expect_dl_data = %{"cbid" => Replacement.filename(r),
                         "csid" => "#{enablement.challenge_set_id}",
                         "hash" => r.digest,
                         "uri" => expect_dl
                        }

      cb_evals
      |> Enum.member?(expect_dl_data)
      |> assert
      end)
  end

  test('get cb evaluation with multiple past replacements',
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         opponent: opponent
       }) do

    challenge_binary = insert(:challenge_binary)
    cset = challenge_binary.challenge_set
    _ancient_enablement = insert(:enablement,
                                 round: ancient_round,
                                 challenge_set: cset)
    enablement = insert(:enablement,
                        round: previous_round,
                        challenge_set: cset)
    cset_name = cset.shortname

    _ancient_replacement = insert(:replacement,
                                  team: opponent,
                                  round: ancient_round,
                                  challenge_binary: challenge_binary)
    replacement = insert(:replacement,
                         team: opponent,
                         round: previous_round,
                         challenge_binary: challenge_binary)

    evaluation_path = eval_path(previous_round,
                                "cb",
                                opponent)

    resp = conn
    |> get(evaluation_path)
    |> json_response(200)

    expected_dl_path = dl_path(opponent,
                               replacement,
                               "cb")

    assert resp ==
      %{"cb" => [
         %{"cbid" => cset_name,
           "csid" => "#{cset.id}",
           "hash" => replacement.digest,
           "uri" => expected_dl_path
     }]}
  end

  test('get cb evaluation for multiple csets from different rounds',
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         opponent: opponent
       }) do
    ancient_enablement = insert(:enablement, round: ancient_round)
    ancient_cset = ancient_enablement.challenge_set
    ancient_cb = insert(:challenge_binary, challenge_set: ancient_cset)
    _previous_enablement_for_ancient =
      insert(:enablement,
             round: previous_round,
             challenge_set: ancient_cset)
    ancient_replacement = insert(:replacement,
                                 team: opponent,
                                 round: ancient_round,
                                 challenge_binary: ancient_cb)

    previous_enablement = insert(:enablement, round: previous_round)
    previous_cset = previous_enablement.challenge_set
    previous_cb = insert(:challenge_binary, challenge_set: previous_cset)
    previous_replacement = insert(:replacement,
                                  team: opponent,
                                  round: previous_round,
                                  challenge_binary: previous_cb)

    evaluation_path = eval_path(previous_round,
                                "cb",
                                opponent)

    resp = conn
    |> get(evaluation_path)
    |> json_response(200)

    assert %{"cb" => cb_evals} = resp
    assert is_list(cb_evals)

    ancient_expectation = %{"cbid" => ancient_cset.shortname,
                            "csid" => "#{ancient_cset.id}",
                            "hash" => ancient_replacement.digest,
                            "uri" => dl_path(opponent,
                                             ancient_replacement,
                                             "cb")}

    assert Enum.member?(cb_evals, ancient_expectation)

    previous_expectation = %{"cbid" => previous_cset.shortname,
                             "csid" => "#{previous_cset.id}",
                             "hash" => previous_replacement.digest,
                             "uri" => dl_path(opponent,
                                              previous_replacement,
                                              "cb")}

    assert Enum.member?(cb_evals, previous_expectation)

  end

  test('get ids evaluation metadata from old round with only one enablement',
       %{
         conn: conn,
         previous_round: previous_round,
         opponent: opponent
       }) do
    firewall = insert(:firewall,
                      team: opponent,
                      round: previous_round)
    enablement = insert(:enablement,
                        challenge_set: firewall.challenge_set,
                        round: previous_round)

    evaluation_path = "/round/~B/evaluation/ids/~B"
    |> :io_lib.format([previous_round.id,
                       opponent.id
                      ])
    |> IO.chardata_to_string

    resp = conn
    |> get(evaluation_path)
    |> json_response(200)

    expected_dl_path = "/dl/~B/ids/~s_~s_~B"
    |> :io_lib.format([opponent.id,
                       firewall.challenge_set.shortname,
                       firewall.digest,
                       firewall.inserted_at |> DateTime.to_unix
                      ])
    |> IO.chardata_to_string

    assert resp ==
      %{"ids" => [
         %{"csid" => "#{firewall.challenge_set.id}",
           "hash" => firewall.digest,
           "uri" => expected_dl_path
       }]}
  end

  test('get ids evaluation with multiple past firewalls',
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         opponent: opponent
       }) do
    cset = insert(:challenge_set)
    _ancient_enablement = insert(:enablement,
                                 round: ancient_round,
                                 challenge_set: cset)
    enablement = insert(:enablement,
                        round: previous_round,
                        challenge_set: cset)
    cset_name = cset.shortname

    _ancient_firewall = insert(:firewall,
                               team: opponent,
                               round: ancient_round,
                               challenge_set: cset)
    firewall = insert(:firewall,
                      team: opponent,
                      round: previous_round,
                      challenge_set: cset)

    evaluation_path = eval_path(previous_round,
                                "ids",
                                opponent)

    resp = conn
    |> get(evaluation_path)
    |> json_response(200)

    expected_dl_path = dl_path(opponent,
                               firewall,
                               "ids")

    assert resp ==
      %{"ids" => [
         %{"csid" => "#{cset.id}",
           "hash" => firewall.digest,
           "uri" => expected_dl_path
     }]}
  end

  test('get ids evaluation for multiple csets from different rounds',
       %{
         conn: conn,
         ancient_round: ancient_round,
         previous_round: previous_round,
         opponent: opponent
       }) do
    ancient_enablement = insert(:enablement, round: ancient_round)
    ancient_cset = ancient_enablement.challenge_set
    _previous_enablement_for_ancient =
      insert(:enablement,
             round: previous_round,
             challenge_set: ancient_cset)
    ancient_firewall = insert(:firewall,
                                team: opponent,
                                round: ancient_round,
                                challenge_set: ancient_cset)

    previous_enablement = insert(:enablement, round: previous_round)
    previous_cset = previous_enablement.challenge_set
    previous_firewall = insert(:firewall,
                               team: opponent,
                               round: previous_round,
                               challenge_set: previous_cset)

    evaluation_path = eval_path(previous_round,
                                "ids",
                                opponent)

    resp = conn
    |> get(evaluation_path)
    |> json_response(200)

    assert %{"ids" => ids_evals} = resp
    assert is_list(ids_evals)

    ancient_expectation = %{"csid" => "#{ancient_cset.id}",
                            "hash" => ancient_firewall.digest,
                            "uri" => dl_path(opponent,
                                             ancient_firewall,
                                             "ids")}

    assert Enum.member?(ids_evals, ancient_expectation)

    previous_expectation = %{"csid" => "#{previous_cset.id}",
                             "hash" => previous_firewall.digest,
                             "uri" => dl_path(opponent,
                                              previous_firewall,
                                              "ids")}

    assert Enum.member?(ids_evals, previous_expectation)

  end

  defp eval_path(round, kind, opponent) do
    "/round/~B/evaluation/~s/~B"
    |> :io_lib.format([round.id,
                       kind,
                       opponent.id
                      ])
    |> IO.chardata_to_string
  end

  defp dl_path(opponent, replacement, "cb") do
    "/dl/~B/cb/~s_~s_~B"
    |> :io_lib.format([opponent.id,
                       Replacement.filename(replacement),
                       replacement.digest,
                       replacement.inserted_at |> DateTime.to_unix
                      ])
  |> IO.chardata_to_string
  end

  defp dl_path(opponent, firewall, "ids") do
    "/dl/~B/ids/~s_~s_~B"
    |> :io_lib.format([opponent.id,
                       firewall.challenge_set.shortname,
                       firewall.digest,
                       firewall.inserted_at |> DateTime.to_unix
                      ])
    |> IO.chardata_to_string
  end

end
