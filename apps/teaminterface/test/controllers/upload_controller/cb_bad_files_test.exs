defmodule Teaminterface.UploadController.CbBadFilesTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  alias Teaminterface.ChallengeBinary

  setup do
    current_round = build(:round) |> make_current |> insert
    enablement = insert(:enablement, round: current_round)

    enabled_cset = enablement.challenge_set

    {:ok,
     enabled_cset: enabled_cset
    }
  end

  test("single CB",
       %{conn: conn,
         enabled_cset: %Teaminterface.ChallengeSet{shortname: name}
        }) do
    resp = conn
    |> post("/rcb",
            %{:csid => name,
              name => fixture("LUNGE_00001.elf", name)})
    |> json_response(200)

    assert resp ==
      %{"error" => ["invalid format"],
        "files" => [
         %{"valid" => "no",
           "file" => name,
           "hash" =>
             "489c2dcd73f84fbaf17012543a199dab35fc69c1bc29b78d71deb532b91e0490"
          }]}
  end

  test("multiple CB, only one",
       %{conn: conn,
         enabled_cset: %Teaminterface.ChallengeSet{shortname: name}
        }) do
    name_1 = "#{name}_1"

    resp = conn
    |> post("/rcb",
            %{:csid => name,
              name_1 => fixture("LUNGE_00001.elf", name_1)})
    |> json_response(200)

    assert resp ==
      %{"error" => ["invalid format"],
        "files" => [
          %{"valid" => "no",
            "file" => name_1,
            "hash" =>
              "489c2dcd73f84fbaf17012543a199dab35fc69c1bc29b78d71deb532b91e0490"
           }]}
  end

  test("multiple CBs at once, one good, one bad",
       %{conn: conn,
         enabled_cset: cset = %Teaminterface.ChallengeSet{shortname: name}
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
              name_1 => fixture("LUNGE_00001.cgc", name_2),
              name_2 => fixture("LUNGE_00001.elf", name_2)})
    |> json_response(200)

    assert resp ==
      %{"error" => ["invalid format"],
        "files" => [
         %{"valid" => "yes",
           "file" => name_1,
           "hash" => "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452"
          },
         %{"valid" => "no",
           "file" => name_2,
           "hash" => "489c2dcd73f84fbaf17012543a199dab35fc69c1bc29b78d71deb532b91e0490"
          }]}
  end

  test("multiple CBs at once, both bad",
       %{conn: conn,
         enabled_cset: cset = %Teaminterface.ChallengeSet{shortname: name}
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
              name_1 => fixture("LUNGE_00001.elf", name_1),
              name_2 => fixture("LUNGE_00001.elf", name_2)})
    |> json_response(200)

    assert resp ==
      %{"error" => ["invalid format"],
        "files" => [
          %{"valid" => "no",
            "file" => name_1,
            "hash" => "489c2dcd73f84fbaf17012543a199dab35fc69c1bc29b78d71deb532b91e0490"
           },
          %{"valid" => "no",
            "file" => name_2,
            "hash" => "489c2dcd73f84fbaf17012543a199dab35fc69c1bc29b78d71deb532b91e0490"
           }]}
  end

  # test "too large of a file", %{conn: conn} do
  #   fname = '/tmp/teaminterface-long-cb'
  #   |> :test_server.temp_name
  #   |> to_string

  #   try do
  #     File.cp fixture_path("LUNGE_00001.elf"), fname
  #     {:ok, _} = File.open(fname, [:append], fn(f) ->
  #       slug = String.duplicate("\n", 50000)
  #       for _n <- (0..1024), do: IO.binwrite(f, slug)
  #     end)

  #     resp = conn
  #     |> post("/rcb",
  #             %{:csid => "LUNGE_00005",
  #               "LUNGE_00005_1" => %Plug.Upload{path: fname,
  #                                               filename: "LUNGE_00005_1"}})
  #     |> json_response(200)

  #     assert resp ==
  #       %{"error" => ["malformed request"],
  #         "files" => [
  #           %{"valid" => "yes",
  #             "file" => "LUNGE_00005_1",
  #             "hash" => "65d16934575b57335d0e294656d7e0ddbd276a1c0ce105bb7ab5307dfa1f84b8"
  #            }]}
  #   after
  #     File.rm_rf fname
  #   end
  # end
end
