defmodule Teaminterface.UploadController.IdsBadTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  setup do
    current_round = build(:round) |> make_current |> insert
    enablement = insert(:enablement, round: current_round)

    enabled_cset = enablement.challenge_set

    {:ok, cset: enabled_cset}
  end

  test "invalid file", %{conn: conn, cset: cset} do
    resp = conn
    |> post("/ids",
            %{:csid => cset.shortname,
              :file => fixture("test_24.rules", "#{cset.shortname}.rules")})
    |> json_response(200)

    assert resp ==
      %{
        "hash" =>
        "8b1b56fd82b759d25d172aab46ad219f76ec9af45ef234deaf93b362b42499d8",
        "file" => "#{cset.shortname}.rules",
        "error" => ["invalid format"]
      }
  end

  test "not enabled CSID", %{conn: conn} do
    non_enabled_cset = insert(:challenge_set)

    resp = conn
    |> post("/ids",
            %{csid: non_enabled_cset.shortname,
              file: fixture("LUNGE_00002.rules",
                            "#{non_enabled_cset.shortname}.rules")})
    |> json_response(200)

    assert resp ==
      %{
        "hash" =>
        "bd5329377285e3240d36312902a5555814154b9a0d746bbc5c63bf2024081e59",
        "file" => "#{non_enabled_cset.shortname}.rules",
        "error" => ["invalid csid"]
      }
  end

  test "invalid CSID", %{conn: conn} do
    resp = conn
    |> post("/ids",
            %{:csid => "invalid",
              :file => fixture("LUNGE_00002.rules", "LUNGE_00002.rules")})
    |> json_response(200)

    assert resp ==
      %{
        "hash" =>
        "bd5329377285e3240d36312902a5555814154b9a0d746bbc5c63bf2024081e59",
        "file" => "LUNGE_00002.rules",
        "error" => ["invalid csid"]
      }
  end

  test "no CSID", %{conn: conn} do
    resp = conn
    |> post("/ids",
            %{:file => fixture("LUNGE_00002.rules", "LUNGE_00002.rules")})
    |> json_response(200)

    assert resp ==
      %{
        "hash" =>
        "bd5329377285e3240d36312902a5555814154b9a0d746bbc5c63bf2024081e59",
        "file" => "LUNGE_00002.rules",
        "error" => ["invalid csid"]
      }
  end

  test "no file", %{conn: conn} do
        resp = conn
    |> post("/ids",
            %{:csid => "LUNGE_00002"})
    |> json_response(200)

    assert resp ==
      %{
        "error" => ["malformed request"]
      }
  end
  test "too large of a file"
end
