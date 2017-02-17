defmodule Teaminterface.Rcb do
  import Teaminterface.UploadUtils

  alias Teaminterface.ChallengeBinary
  alias Teaminterface.Repo
  alias Teaminterface.Replacement

  def fake_upload(key,
                  %Plug.Upload{path: _path, filename: _filename} = up_params) do
    validate_upload(key, up_params)
  end

  def upload(key,
             %Plug.Upload{} = up_params,
             %Teaminterface.Team{} = team,
             %Teaminterface.Enablement{} = enablement
      ) do
    validity_params = key
    |> validate_upload(up_params)
    |> persist_upload(up_params, team, enablement)
  end

  defp validate_upload(
        key,
        %Plug.Upload{path: path, filename: _filename} = _up_params) do
    validity = cond do
      too_long(path) -> "no"
      not_cgcef(path) -> "no"
      true -> "yes"
    end

    %{valid: validity, hash: hash_file(path), file: key}
  end

  defp determine_persistence(team_id, round_id, cset_id, digest, filename) do
    case Replacement.recent(team_id, cset_id, filename) do
      [] -> :create
      [%Replacement{digest: ^digest} | _rest] ->
        :noop # replacement is same
      [
        %Replacement{round_id: ^round_id},
        %Replacement{round_id: _different_round, digest: ^digest}
      ] ->
        :revert # roll back to a previous round's version
      [%Replacement{round_id: ^round_id} | _rest] ->
        :update
      [%Replacement{round_id: _other_round} | _rest] ->
        :create # replacing different digest from different round
    end
  end

  defp persist_upload(
        %{valid: "yes", hash: digest, file: key} = validity_params,
        %Plug.Upload{path: path, filename: _filename} = _up_params,
        %Teaminterface.Team{id: team_id},
        %Teaminterface.Enablement{round_id: round_id,
                                  challenge_set_id: cset_id}) do

    case determine_persistence(team_id, round_id, cset_id, digest, key) do
      :noop -> validity_params
      :revert -> revert(team_id, round_id, cset_id, validity_params)
      :update -> update(team_id, round_id, cset_id, validity_params, path)
      :create -> create(team_id, round_id, cset_id, validity_params, path)
    end
  end

  defp persist_upload(validity_params,
                      _up_params,
                      _team,
                      _enablement) do
    validity_params
  end

  defp create(team_id,
              round_id,
              cset_id,
              %{valid: "yes", hash: digest, file: key} = validity_params,
              path) do
    cb = ChallengeBinary.find_by_filename(key)

    rec = %Teaminterface.Replacement{
      challenge_binary_id: cb.id,
      digest: digest,
      team_id: team_id,
      round_id: round_id,
      size: size(path)
    }

    copy(team_id, key, path)

    Repo.insert rec

    validity_params
  end

  defp update(team_id,
              round_id,
              cset_id,
              %{valid: "yes", hash: digest, file: key} = validity_params,
              path) do
    copy(team_id, key, path)

    cb = ChallengeBinary.find_by_filename(key)

    {:ok, _struct} = Teaminterface.Repo.get_by(Replacement,
                                               team_id: team_id,
                                               round_id: round_id,
                                               challenge_binary_id: cb.id)
    |> Ecto.Changeset.change(digest: digest,
                             size: size(path))
    |> Repo.update

    validity_params
  end

  defp revert(team_id,
              round_id,
              cset_id,
              %{valid: "yes", hash: digest, file: key} = validity_params) do

    cb = ChallengeBinary.find_by_filename(key)

    {:ok, _struct} = Teaminterface.Repo.get_by(Replacement,
                                               team_id: team_id,
                                               round_id: round_id,
                                               challenge_binary_id: cb.id)
    |> Repo.delete

    validity_params
  end

  defp copy(team_id, key, src_path) do
    dest_path = path(team_id, key)

    :ok = attempt_copy(src_path, dest_path, 3)
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

  defp path(team_id, key) do
    upload_root
    |> Path.join("incoming/#{team_id}/rcb/#{key}")
  end
end
