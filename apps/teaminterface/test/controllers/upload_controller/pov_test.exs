defmodule Teaminterface.UploadController.PovTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  setup do
    current_round = build(:round) |> make_current |> insert
    enablement = insert(:enablement, round: current_round)

    enabled_cset = enablement.challenge_set

    target = insert(:team)

    {:ok, cset: enabled_cset, target: target}
  end

  test "plausible pov", %{conn: conn, cset: cset, target: target} do
    resp = conn
    |> post("/pov",
            %{:csid => cset.shortname,
              :file => fixture("LUNGE_00001.cgc", "#{cset.shortname}.pov"),
              :team => target.id,
              :throws => "10"})
    |> json_response(200)

    assert resp ==
      %{
        "hash" =>
        "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452",
        "round" => Teaminterface.Round.current.id,
        "file" => "#{cset.shortname}.pov"
      }
  end
end
