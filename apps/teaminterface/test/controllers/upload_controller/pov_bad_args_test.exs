defmodule Teaminterface.UploadController.PovBadArgsTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  setup do
    current_round = build(:round) |> make_current |> insert
    enablement = insert(:enablement, round: current_round)

    enabled_cset = enablement.challenge_set

    target = insert(:team)

    {:ok, cset: enabled_cset, target: target}
  end

  test "team is too low", state do
    assert req(state, %{team: "0"}) == resp(state, %{
          "error" => ["invalid team"]
                                       })
  end

  test "team is too high", state do
    assert req(state, %{team: "100"}) == resp(state, %{
          "error" => ["invalid team"]
                                         })
  end

  test "can't throw against ourselves", state do
    assert req(state, %{team: "5"}) == resp(state, %{
          "error" => ["invalid team"]
                                       })
  end

  test "too many throws", state do
    assert req(state, %{throws: "15"}) == resp(state, %{
          "error" => ["invalid throws"]
      })
  end

  test "too few throws", state do
    assert req(state, %{throws: "-1"}) == resp(state, %{
      "error" => ["invalid throws"]
      })
  end

  test "no throws", state do
    assert req(state, %{throws: "0"}) == resp(state, %{
      "error" => ["invalid throws"]
      })
  end

  test "no teams", state = %{conn: conn, cset: cset, target: target} do
    resp = conn
    |> post("/pov",
            default_params(cset, target)
            |> Map.delete(:team))
    |> json_response(200)

    assert resp == resp(state, %{
          "error" => ["invalid team"]
                    })
  end

  test "no file", _state = %{conn: conn, cset: cset, target: target} do
    resp = conn
    |> post("/pov",
            default_params(cset, target)
            |> Map.delete(:file))
    |> json_response(200)

    assert resp == %{"error" => ["malformed request"]}
  end

  test "no csid", state = %{conn: conn, cset: cset, target: target} do
    resp = conn
    |> post("/pov",
            default_params(cset, target)
            |> Map.delete(:csid))
    |> json_response(200)

    assert resp == resp(state, %{"error" => ["invalid csid"]})
  end

  test("no csid and invalid throws",
       state = %{conn: conn, cset: cset, target: target}) do
    resp = conn
    |> post("/pov",
            default_params(cset, target)
            |> Map.delete(:csid)
            |> Map.merge(%{"throws" => "-1"}))
    |> json_response(200)

    assert resp == resp(state, %{"error" => ["invalid csid", "invalid throws"]})
  end

  test "upload ELF", state = %{cset: cset} do
    assert req(state,
               %{file: fixture("LUNGE_00001.elf", "#{cset.shortname}.pov")}) ==
      resp(state, %{
            "error" => ["invalid format"],
            "hash" =>
              "489c2dcd73f84fbaf17012543a199dab35fc69c1bc29b78d71deb532b91e0490"
       })
  end

  test "upload 10kb padded CGCEF" # succeed
  test "upload 10mb padded CGCEF" # fail

  defp default_params(
        _cset = %Teaminterface.ChallengeSet{shortname: name},
        _target = %Teaminterface.Team{id: target_id}) do
    %{
      :csid => name,
      :file => fixture("LUNGE_00001.cgc", "#{name}.pov"),
      :team => target_id,
      :throws => "10"}
  end

  defp req(_state = %{conn: conn, cset: cset, target: target},
           merge_params) do
    conn
    |> post("/pov",
            Map.merge(default_params(cset, target), merge_params))
    |> json_response(200)
  end

  defp resp(_state = %{cset: cset}, merge_params) do
    Map.merge(%{
          "hash" =>
            "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452",
          "file" => "#{cset.shortname}.pov"},
              merge_params)
  end
end
