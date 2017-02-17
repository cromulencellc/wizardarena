defmodule Teaminterface.Ids do
  import Teaminterface.UploadUtils

  alias Teaminterface.Repo

  alias Teaminterface.Firewall

  def upload(nil,
             _team,
             %Plug.Upload{path: path, filename: filename} = _ids_file) do
    %{hash: hash_file(path), file: filename, error: ["invalid csid"]}
  end

  def upload(enablement,
             team,
             %Plug.Upload{path: path, filename: filename} = ids_file) do
    result = %{hash: hash_file(path), file: filename}

    cond do
      not_cgcids(path) -> %{error: ["invalid format"]}
      true -> %{round: enablement.round_id}
    end
    |> Map.merge(result)
    |> persist_upload(ids_file, team, enablement)
  end

  defp persist_upload(
        %{error: _error_text} = validity_params,
        _up_params,
        _team,
        _enablement) do
    validity_params
  end

  defp persist_upload(
        %{round: round_id, hash: digest, file: _key} = validity_params,
        %Plug.Upload{path: path} = _up_params,
        %Teaminterface.Team{id: team_id} = _team,
        %Teaminterface.Enablement{round_id: round_id,
                                  challenge_set_id: cset_id} = _enablement) do
    cset = cond do
      fw = Repo.get_by(Firewall,
                       team_id: team_id,
                       round_id: round_id,
                       challenge_set_id: cset_id) ->
        fw
      true -> %Firewall{
              team_id: team_id,
              round_id: round_id,
              challenge_set_id: cset_id
          }
    end
    |> Firewall.changeset(%{digest: digest})

    dest_path = upload_root
    |> Path.join("incoming/#{team_id}/ids/#{cset_id}.ids")

    :ok = attempt_copy(path, dest_path, 3)

    Teaminterface.Repo.insert_or_update! cset

    validity_params
  end

  defp attempt_copy(_path, _dest, 0) do
    false
  end

  defp attempt_copy(path, dest_path, tries) do
    try do
      :ok = dest_path
      |> Path.dirname
      |> File.mkdir_p

      :ok = File.cp(path, dest_path)
    rescue
      MatchError -> attempt_copy(path, dest_path, tries - 1)
    else
      _ -> :ok
    end
  end

  defp not_cgcids(path) do
    {:ok, rules} = File.open(path, [:read], fn(fh) ->
      IO.binread(fh, :all)
    end)
    !(Teaminterface.IdsUtils.parse(rules))
  end
end
