# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Teaminterface.Repo.insert!(%Teaminterface.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Teaminterface.ChallengeBinary
alias Teaminterface.ChallengeSet
alias Teaminterface.Enablement
alias Teaminterface.Repo
alias Teaminterface.Round
alias Teaminterface.Team

teams = __DIR__
|> Path.join("./teams.tsv")
|> Path.expand
|> File.stream!([:read], :line)
|> Enum.map(&Team.seed_from_tsv_row(&1))
|> List.delete(nil)

rounds = [first_round | _other_rounds] = (1..10)
|> Enum.map(fn(n) ->
  case Repo.get(Round, n) do
    nil ->
      Repo.insert!(
        %Round{id: n,
               nickname: Teaminterface.RoundNickname.for(n),
               seed: "#{n}",
               started_at: Timex.DateTime.now,
               finished_at: Timex.DateTime.now
              })
    round -> round
  end
end)

rounds
|> List.last
|> Map.put(:finished_at, nil)
|> Repo.update!

csets = (1..4)
|> Enum.map(fn(n) ->
  shortname = "SEEDS_0000#{n}"

  cset = case Repo.get(ChallengeSet, n) do
           nil ->
             Repo.insert!(
               %ChallengeSet{id: n,
                             name: "seeded challenge set #{n}",
                             shortname: shortname})
           found -> found
         end
  cb = case Ecto.assoc(cset, :challenge_binaries) |> Repo.all do
          [] ->
            Repo.insert!(
              %ChallengeBinary{challenge_set_id: cset.id,
                               index: 0,
                               size: 85548})
          [some_cb | _rest] -> some_cb
       end
  [first_enablement, second_enablement | _enablements] = rounds
  |> Enum.map(fn(r) ->
    case Repo.get_by(Enablement,
                     %{round_id: r.id, challenge_set_id: cset.id}) do
      nil ->
        Repo.insert!(%Enablement{round_id: r.id, challenge_set_id: cset.id})
      some_enablement -> some_enablement
    end
  end)

  cbid = ChallengeBinary.cbid(cb)
  rcb_path = __DIR__
  |> Path.join("../../test/support/fixtures")
  |> Path.join("LUNGE_00001.cgc")
  |> Path.expand
  ids_path = __DIR__
  |> Path.join("../../test/support/fixtures")
  |> Path.join("LUNGE_00002.rules")
  |> Path.expand

  teams
  |> Enum.each(fn(team) ->
    Teaminterface.Rcb.upload(
      cbid,
      %Plug.Upload{path: rcb_path, filename: cbid},
      team,
      first_enablement)

    Teaminterface.Ids.upload(
      first_enablement,
      team,
      %Plug.Upload{path: ids_path, filename: "#{cset.shortname}.ids"})

    [target | _rest] = teams |> List.delete(team) |> Enum.shuffle

    Teaminterface.Pov.upload(
      second_enablement,
      team,
      target,
      1,
      %Plug.Upload{path: rcb_path, filename: "#{cset.shortname}.pov"})
  end)
end)

~w{rounds teams challenge_sets challenge_binaries enablements replacements
   firewalls proofs}
|> Teaminterface.Repo.fix_counter
