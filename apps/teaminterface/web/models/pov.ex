defmodule Teaminterface.Pov do
  import Teaminterface.UploadUtils

  alias Teaminterface.Proof

  def upload(nil, _team, _target_team, throw_count,
             %Plug.Upload{path: path, filename: filename} = _pov_file) do
    result = %{hash: hash_file(path), file: filename}

    cond do
      invalid_throws(throw_count) ->
        %{error: ["invalid csid", "invalid throws"]}
      true ->
        %{error: ["invalid csid"]}
    end
    |> Map.merge(result)
  end

  def upload(_enablement,
             _team,
             nil,
             _throw_count,
             %Plug.Upload{path: path, filename: filename} = _pov_file) do
    %{hash: hash_file(path), file: filename, error: ["invalid team"]}
  end

  def upload(_enablement,
             team,
             team,
             _throw_count,
             %Plug.Upload{path: path, filename: filename} = _pov_file) do
    %{hash: hash_file(path), file: filename, error: ["invalid team"]}
  end

  def upload(enablement,
             team,
             target_team,
             throw_count,
             %Plug.Upload{path: path, filename: filename} = pov_file) do

    result = %{hash: hash_file(path), file: filename}

    cond do
      invalid_throws(throw_count) -> %{error: ["invalid throws"]}
      too_long(path) -> %{error: ["malformed request"]}
      not_cgcef(path) -> %{error: ["invalid format"]}
      true -> %{round: enablement.round_id}
    end
    |> Map.merge(result)
    |> persist_upload(pov_file, team, target_team, enablement, throw_count)
  end

  defp persist_upload(
        %{error: _error_text} = validity_params,
        _up_params,
        _team,
        _target,
        _enablement,
        _throw_count) do
    validity_params
  end

  defp persist_upload(
        %{round: round_id, hash: digest, file: _key} = validity_params,
        %Plug.Upload{path: path} = _up_params,
        %Teaminterface.Team{id: team_id} = _team,
        %Teaminterface.Team{id: target_id} = _target,
        %Teaminterface.Enablement{round_id: round_id,
                                  challenge_set_id: cset_id} = _enablement,
        throw_count
      ) do


    dest_path = upload_root
    |> Path.join("incoming/#{team_id}/pov/#{cset_id}/#{target_id}.pov")

    :ok = attempt_copy(path, dest_path, 3)

    case Teaminterface.Repo.get_by(Proof,
                                   %{team_id: team_id,
                                     target_id: target_id,
                                     round_id: round_id,
                                     challenge_set_id: cset_id}) do
      nil -> %Proof{team_id: team_id,
                   target_id: target_id,
                   round_id: round_id,
                   challenge_set_id: cset_id}
      p = %Proof{} -> p
    end
    |> Proof.changeset(%{
          digest: digest,
          throws: throw_count,
                   })
    |> Teaminterface.Repo.insert_or_update!

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

  defp invalid_throws(throw_count) when (
      (throw_count > 10) or (throw_count < 1)
      ) do
    true
  end

  defp invalid_throws(_throw_count) do
    false
  end
end
