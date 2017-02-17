defmodule Teaminterface.UploadController.IdsTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  setup do
    current_round = build(:round) |> make_current |> insert
    enablement = insert(:enablement, round: current_round)

    enabled_cset = enablement.challenge_set

    {:ok, cset: enabled_cset}
  end

  test "upload ids", %{conn: conn, cset: cset} do
    resp = conn
    |> post("/ids",
            %{:csid => cset.shortname,
              :file => fixture("LUNGE_00002.rules", "#{cset.shortname}.rules")})
    |> json_response(200)

    assert resp ==
      %{
        "hash" =>
        "bd5329377285e3240d36312902a5555814154b9a0d746bbc5c63bf2024081e59",
        "round" => Teaminterface.Round.current.id,
        "file" => "#{cset.shortname}.rules"
      }
  end
end
