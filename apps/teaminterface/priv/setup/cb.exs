IO.puts "USAGE: mix run priv/setup/cb.exs PATH_TO_ORIGINAL_CB [ACBID_00001_2]"

~w{challenge_sets challenge_binaries enablements replacements firewalls}
|> Teaminterface.Repo.fix_counter


filename = Enum.at(System.argv, 0)

planned_cbid = filename
|> Path.basename
|> Path.rootname

cbid = Enum.at(System.argv, 1, planned_cbid)

IO.puts "Loading #{filename} into wizard arena as cb #{cbid}"

size = Teaminterface.UploadUtils.size filename
hash = Teaminterface.UploadUtils.hash_file filename

IO.puts "#{size} bytes, #{hash}"

current_cb = case Teaminterface.ChallengeBinary.find_by_filename(cbid) do
                nil -> %Teaminterface.ChallengeBinary{}
                found -> found
              end

IO.puts "current cb"
IO.inspect current_cb

current_cset = cond do
  !is_nil(current_cb.challenge_set_id) ->
    Ecto.assoc(current_cb, :challenge_set)
    |> Teaminterface.Repo.one
  found = Teaminterface.ChallengeSet.find_filename(cbid) -> found
  is_nil(current_cb.challenge_set_id) -> %Teaminterface.ChallengeSet{}
end

IO.puts "current cset"
IO.inspect current_cset

shortname = Teaminterface.ChallengeSet.filename_to_shortname(cbid)

persisted_cset = current_cset
|> Teaminterface.ChallengeSet.changeset(%{name: shortname,
                                          shortname: shortname})
|> Teaminterface.Repo.insert_or_update!

IO.inspect persisted_cset

persisted_cb = current_cb
|> IO.inspect
|> Teaminterface.ChallengeBinary.changeset(%{
      challenge_set: persisted_cset,
      challenge_set_id: persisted_cset.id,
      size: size,
      index:
      Teaminterface.ChallengeBinary.get_index_from_filename(cbid),
      patched_size: 0})
|> IO.inspect
|> Teaminterface.Repo.insert_or_update!

IO.inspect persisted_cb

first_round = Teaminterface.Repo.get(Teaminterface.Round, 0)
first_enablement = case Teaminterface.Repo.get_by(
                         Teaminterface.Enablement,
                         round_id: first_round.id,
                         challenge_set_id: persisted_cset.id) do
                     nil ->
                       %Teaminterface.Enablement{round_id: first_round.id,
                                                 challenge_set_id: persisted_cset.id}
                       |> Teaminterface.Repo.insert!
                     found -> found
                   end

_teams = Teaminterface.Team
|> Teaminterface.Repo.all
|> Enum.each(fn(team) ->
  if is_nil(Teaminterface.Repo.get_by(
            Teaminterface.Replacement,
            team_id: team.id,
            round_id: first_round.id,
            challenge_binary_id: persisted_cb.id)) do
    Teaminterface.Rcb.upload(
      cbid,
      %Plug.Upload{path: filename, filename: cbid}, # lol
      team,
      first_enablement)

    repl = Teaminterface.Repo.get_by(
      Teaminterface.Replacement,
      team_id: team.id,
      round_id: first_round.id,
      challenge_binary_id: persisted_cb.id)

    path = Teaminterface.DownloadUtils.path(
      %{repl | challenge_binary: persisted_cb,
        challenge_set: persisted_cset})

    IO.inspect path

    path |> Path.dirname |> File.mkdir_p

    File.cp(filename, path)
  end

  if is_nil(Teaminterface.Repo.get_by(
            Teaminterface.Firewall,
            team_id: team.id,
            round_id: first_round.id,
            challenge_set_id: persisted_cset.id)) do
    Teaminterface.Ids.upload(
      first_enablement,
      team,
      %Plug.Upload{path: "/dev/null",
                   filename: "#{persisted_cset.shortname}.ids"})

    fw = Teaminterface.Repo.get_by(
      Teaminterface.Firewall,
      team_id: team.id,
      round_id: first_round.id,
      challenge_set_id: persisted_cset.id)

    path = Teaminterface.DownloadUtils.path(
      %{fw | challenge_set: persisted_cset})

    path |> Path.dirname |> File.mkdir_p

    File.cp("/dev/null", path)

  end
end)

~w{challenge_sets challenge_binaries enablements replacements firewalls}
|> Teaminterface.Repo.fix_counter
