defmodule Teaminterface.PovUploadController do
  use Teaminterface.Web, :controller

  import Teaminterface.UploadUtils, only: [get_enablement_for_cset: 1]

  def pov(conn,
          _params = %{"csid" => csid,
                      "file" => pov_file,
                      "team" => target,
                      "throws" => throws}) do

    csid
    |> get_enablement_for_cset
    |> pov_with_cset(conn, pov_file, target, throws)
  end

  def pov(conn, _params = %{"csid" => _csid,
                            "team" => _target,
                            "throws" => _throws}) do
    json(conn, %{"error" => ["malformed request"]})
  end

  def pov(conn, params = %{"csid" => _csid,
                            "throws" => _throws}) do
    pov(conn, Map.merge(params, %{"team" => "-1"}))
  end

  def pov(conn, params = %{"throws" => _throws}) do
    pov(conn, Map.merge(params, %{"csid" => :invalid}))
  end

  defp pov_with_cset(enablement, conn, pov_file, target, throws) do
    team = conn.assigns[:authed_team]
    target = Teaminterface.Repo.get(Teaminterface.Team, target)
    throw_count = String.to_integer(throws)

    json(conn,
         Teaminterface.Pov.upload(enablement,
                                  team,
                                  target,
                                  throw_count,
                                  pov_file))
  end
end
