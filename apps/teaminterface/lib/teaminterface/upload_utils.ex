defmodule Teaminterface.UploadUtils do
  def size(path) do
    {:ok, stat} = path
    |> File.stat

    stat.size
  end

  def too_long(path) do
    case size(path) do
      (0..(1024*50000)) -> true
      _other -> false
    end
  end

  def not_cgcef(path) do
    case Cgcef.verify(path) do
      :ok -> false
      _other -> true
    end
  end

  def hash_file(fname) do
    {:ok, digest} = File.open(fname, [:read], fn(fh) ->
      :crypto.hash_init(:sha256)
      |> hash_chunk(fh)
      |> Base.encode16
      |> String.downcase
    end)

    digest
  end

  defp hash_chunk(ctx, fh) do
    case IO.binread(fh, 4096) do
      :eof ->
        :crypto.hash_final(ctx)
      data ->
        ctx
        |> :crypto.hash_update(data)
        |> hash_chunk(fh)
    end
  end

  def get_enablement_for_cset(:invalid) do
    nil
  end

  def get_enablement_for_cset(csid) do
    case Integer.parse(csid) do
      {cs_int, ""} -> get_enablement_for_int_cset(cs_int)
      :error -> get_enablement_for_string_cset(csid)
    end
  end

  defp get_enablement_for_int_cset(cs_int) do
    Teaminterface.Repo.get(Teaminterface.ChallengeSet,
                           cs_int)
    |> get_enablement_for_materialized_cset
  end

  defp get_enablement_for_string_cset(csid) do
    Teaminterface.Repo.get_by(Teaminterface.ChallengeSet,
                              shortname: csid)
    |> get_enablement_for_materialized_cset
  end

  defp get_enablement_for_materialized_cset(cset) do
    round = Teaminterface.Round.current

    cond do
      (nil == cset) -> nil
      (nil == round) -> nil
      true -> Teaminterface.Repo.
        get_by(Teaminterface.Enablement,
               challenge_set_id: cset.id,
               round_id: round.id)
    end
  end

  def get_enabled_cset(csid) do
    case get_enablement_for_cset(csid) do
      nil -> nil
      %Teaminterface.Enablement{challenge_set_id: cset_id} ->
        Teaminterface.Repo.
        get_by(Teaminterface.ChallengeSet,
               id: cset_id)
    end
  end

  def upload_root do
    Application.get_env(:teaminterface, :upload_root)
  end
end
