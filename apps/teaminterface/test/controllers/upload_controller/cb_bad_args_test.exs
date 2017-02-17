defmodule Teaminterface.UploadController.CbBadArgsTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  setup do
    non_enabled_cset = insert(:challenge_set)
    current_round = build(:round) |> make_current |> insert
    enablement = insert(:enablement, round: current_round)

    enabled_cset = enablement.challenge_set

    {:ok,
     non_enabled_cset: non_enabled_cset,
     enabled_cset: enabled_cset
    }
  end

  test "single CB - invalid csid", %{conn: conn} do
    resp = conn
    |> post("/rcb",
            %{:csid => "invalid",
              'invalid' => fixture("LUNGE_00001.cgc", "invalid")})
    |> json_response(200)

    assert resp == %{"error" => ["invalid csid"]}
  end

  test "single CB - not enabled csid", %{conn: conn, non_enabled_cset: cset} do
    resp = conn
    |> post("/rcb",
            %{:csid => cset.shortname,
              cset.shortname => fixture("LUNGE_00001.cgc", cset.shortname)})
    |> json_response(200)

    assert resp == %{"error" => ["invalid csid"]}
  end


  test "single CB - invalid cbid", %{conn: conn, enabled_cset: cset} do
    resp = conn
    |> post("/rcb",
            %{:csid => cset.shortname,
              "invalid_1" => fixture("LUNGE_00001.cgc", "invalid_1")})
    |> json_response(200)

    assert resp ==
      %{"error" => ["invalid cbid"],
        "files" => [
          %{"valid" => "yes",
            "file" => "invalid_1",
            "hash" =>
              "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
            }]}
  end

  test "No CBs", %{conn: conn, enabled_cset: cset} do
        resp = conn
    |> post("/rcb",
            %{:csid => cset.shortname})
    |> json_response(200)

    assert resp == %{"error" => ["malformed request"]}
  end
end
