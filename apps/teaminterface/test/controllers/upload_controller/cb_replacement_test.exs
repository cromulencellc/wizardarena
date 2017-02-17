defmodule Teaminterface.UploadController.CbReplacementTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  setup do
    previous_round = build(:round) |> make_over |> insert
    previous_enablement = insert(:enablement, round: previous_round)

    cset = previous_enablement.challenge_set

    current_round = build(:round) |> make_current |> insert
    _current_enablement = insert(:enablement,
                                 round: current_round,
                                 challenge_set: cset)

    {:ok,
     cset: cset,
     current_round: current_round,
     previous_round: previous_round}
  end

  test("replace a cb uploaded this round with a new one",
       %{conn: conn,
         cset: cset = %Teaminterface.ChallengeSet{shortname: name, id: cset_id},
         current_round: current_round
        }) do
    cb = insert(:challenge_binary, challenge_set: cset)

    first_resp = conn
    |> post("/rcb",
            %{:csid => name,
              name => fixture("LUNGE_00001_modified.cgc", name)})
    |> json_response(200)

    assert first_resp ==
      %{"round" => current_round.id,
        "files" => [
          %{"valid" => "yes",
            "file" => name,
            "hash" =>
              "90e10f509d17885e19f0aa4d77637e69a383719e3e236ba9fa9219f18c5f0f73"
           }]}

    found_original = Teaminterface.Repo.get_by(Teaminterface.Replacement,
      round_id: current_round.id,
      challenge_binary_id: cb.id)

    assert found_original.digest ==
      "90e10f509d17885e19f0aa4d77637e69a383719e3e236ba9fa9219f18c5f0f73"

    second_resp = conn
    |> post("/rcb",
            %{:csid => name,
              name => fixture("LUNGE_00001.cgc", name)})
    |> json_response(200)

    assert second_resp ==
      %{"round" => current_round.id,
        "files" => [
         %{"valid" => "yes",
           "file" => name,
           "hash" =>
           "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
          }]}
    # check to make sure only second upload is persisted
    found_replacement = Teaminterface.Repo.get_by(Teaminterface.Replacement,
                                                  round_id: current_round.id,
                                                  challenge_binary_id: cb.id)

    assert found_replacement.digest ==
      "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
  end

  test("de-replace a cb uploaded this round with one from previous round",
    %{conn: conn,
      cset: cset = %Teaminterface.ChallengeSet{shortname: name, id: cset_id},
      current_round: current_round,
      previous_round: previous_round,
      team: team
     }) do
    cb = insert(:challenge_binary, challenge_set: cset)

    # bad people stuff
    Teaminterface.Rcb.upload(name,
                             fixture("LUNGE_00001.cgc", name),
                             team,
                             %Teaminterface.Enablement{
                               round_id: previous_round.id,
                               challenge_set_id: cset_id})

    original_replacement =
      Teaminterface.Repo.get_by(Teaminterface.Replacement,
                                round_id: previous_round.id,
                                challenge_binary_id: cb.id)

    assert original_replacement.digest ==
      "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"

    first_resp = conn
    |> post("/rcb",
            %{:csid => name,
              name => fixture("LUNGE_00001_modified.cgc", name)})
    |> json_response(200)

    assert first_resp ==
      %{"round" => current_round.id,
        "files" => [
         %{"valid" => "yes",
           "file" => name,
           "hash" =>
             "90e10f509d17885e19f0aa4d77637e69a383719e3e236ba9fa9219f18c5f0f73"
          }]}

    found_this_round = Teaminterface.Repo.get_by(Teaminterface.Replacement,
      round_id: current_round.id,
      challenge_binary_id: cb.id)

    assert found_this_round.digest ==
      "90e10f509d17885e19f0aa4d77637e69a383719e3e236ba9fa9219f18c5f0f73"


    second_resp = conn
    |> post("/rcb",
            %{:csid => name,
              name => fixture("LUNGE_00001.cgc", name)})
    |> json_response(200)

    assert second_resp ==
      %{"round" => current_round.id,
        "files" => [
         %{"valid" => "yes",
           "file" => name,
           "hash" =>
           "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
         }]}

    # check to make sure only second upload is gone
    found_replacement = Teaminterface.Repo.get_by(Teaminterface.Replacement,
                                                  round_id: current_round.id,
                                                  challenge_binary_id: cb.id)

    assert found_replacement == nil
  end
end
