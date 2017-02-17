defmodule Teaminterface.RcbUploadController do
  use Teaminterface.Web, :controller

  import Teaminterface.UploadUtils, only: [get_enablement_for_cset: 1]

  alias Teaminterface.ChallengeSet
  alias Teaminterface.Enablement
  alias Teaminterface.Rcb

  alias Teaminterface.Repo

  def rcb(conn, params = %{"csid" => csid}) do
    rcb_with_cset(conn,
                  params,
                  get_enablement_for_cset(csid))
  end

  def rcb(conn, _params) do
    json conn, %{error: ["invalid csid"]}
  end

  def rcb_with_cset(conn, _params, nil) do
    json conn, %{error: ["invalid csid"]}
  end

  def rcb_with_cset(conn, params, enablement) do
    case rcb_keys(params, enablement) do
      [] -> process_possible_rcbs(conn, params)
      keys -> process_rcbs(conn, keys, params, enablement)
    end
  end

  defp process_possible_rcbs(conn, params) do
    plausible_uploads = params
    |> Map.to_list
    |> Enum.filter(fn({_k, v}) ->
      case v do
        %Plug.Upload{} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn({k, v}) ->
      Rcb.fake_upload(k, v)
    end)

    json(conn,
         case plausible_uploads do
           [] -> %{error: ["malformed request"]}
           _ -> %{error: ["invalid cbid"], files: plausible_uploads}
         end)
  end

  defp process_rcbs(conn, keys, params, enablement) do
    {rcbs, errs} = rcb_values(keys, params)
    |> process_uploads(conn.assigns[:authed_team], enablement)

    full_resp = case errs do
                  [] -> %{round: enablement.round_id, files: rcbs}
                  errors -> %{files: rcbs, error: Enum.uniq(errors)}
                end

    json conn, full_resp
  end

  defp rcb_keys(params = %{"csid" => _csid},
                _enablement = %Enablement{challenge_set: cset = %ChallengeSet{shortname: shortname}}) do
    params
    |> Map.keys()
    |> Enum.filter(fn(k) ->
      String.starts_with?(k, shortname)
    end)
  end

  defp rcb_keys(params,
                enablement = %Enablement{}) do
    cset = Ecto.assoc(enablement, :challenge_set) |> Repo.one

    rcb_keys(params,
             %{enablement | challenge_set: cset})
  end


  defp rcb_values(keys, params) do
    params
    |> Map.take(keys)
    |> Map.to_list
    |> Enum.reverse
  end

  defp process_uploads(rcb_vals, team, enablement) do
    Enum.reduce(rcb_vals, {[], []}, fn({key, plug_upload}, {acc, errs}) ->
      case Rcb.upload(key, plug_upload, team, enablement) do
        result = %{valid: "yes"} -> {[result | acc], errs}
        result = %{valid: "no"} -> {[result | acc], ["invalid format"|errs]}
      end
    end)
  end
end
