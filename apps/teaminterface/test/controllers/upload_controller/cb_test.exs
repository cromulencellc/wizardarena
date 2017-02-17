defmodule Teaminterface.UploadController.CbTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  alias Teaminterface.ChallengeBinary

  setup do
    current_round = build(:round) |> make_current |> insert
    enablement = insert(:enablement, round: current_round)

    enabled_cset = enablement.challenge_set

    {:ok, cset: enabled_cset, current_round: current_round}
  end

  test("single CB",
       %{conn: conn,
         cset: cset = %Teaminterface.ChallengeSet{shortname: name},
         current_round: current_round
        }) do
    _cb = insert(:challenge_binary, challenge_set: cset)

    resp = conn
    |> post("/rcb",
            %{:csid => name,
              name => fixture("LUNGE_00001.cgc", name)})
    |> json_response(200)

    assert resp ==
      %{"round" => current_round.id,
        "files" => [
         %{"valid" => "yes",
           "file" => name,
           "hash" =>
             "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
          }]}
  end

  test("single CB with integer cbid",
       %{conn: conn,
         cset: cset = %Teaminterface.ChallengeSet{id: id, shortname: name},
         current_round: current_round
        }) do
    _cb = insert(:challenge_binary, challenge_set: cset)

    resp = conn
    |> post("/rcb",
            %{:csid => "#{id}",
              name => fixture("LUNGE_00001.cgc", name)})
    |> json_response(200)

    assert resp ==
      %{"round" => current_round.id,
        "files" => [
         %{"valid" => "yes",
           "file" => name,
           "hash" =>
             "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
          }]}
  end

  test("multiple CB, only one",
       %{conn: conn,
         cset: cset = %Teaminterface.ChallengeSet{shortname: name},
         current_round: current_round
        }) do
    cb = insert(:challenge_binary, challenge_set: cset)
    resp = conn

    |> post("/rcb",
            %{:csid => name,
              ChallengeBinary.cbid(cb) => fixture("LUNGE_00001.cgc", cb)})
    |> json_response(200)

    assert resp ==
      %{"round" => current_round.id,
        "files" => [
         %{"valid" => "yes",
           "file" => ChallengeBinary.cbid(cb),
           "hash" =>
             "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
          }]}
  end

  test("multiple CBs at once",
       %{conn: conn,
         cset: cset = %Teaminterface.ChallengeSet{shortname: name},
         current_round: current_round
        }) do
    cbs = (1..2)
    |> Enum.map(&insert(:challenge_binary,
                        challenge_set: cset,
                        index: &1))

    [name_1, name_2] = cbs
    |> Enum.map(&ChallengeBinary.cbid(&1))

    resp = conn
    |> post("/rcb",
            %{:csid => name,
              name_1 => fixture("LUNGE_00001.cgc", name_1),
              name_2 => fixture("LUNGE_00001.cgc", name_2)})
    |> json_response(200)

    assert resp ==
      %{"round" => current_round.id,
        "files" => [
         %{"valid" => "yes",
           "file" => name_1,
           "hash" => "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
          },
         %{"valid" => "yes",
           "file" => name_2,
           "hash" => "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
          }]}
  end
end
