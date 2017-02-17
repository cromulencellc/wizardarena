defmodule Teaminterface.IdsUploadController do
  use Teaminterface.Web, :controller

  import Teaminterface.UploadUtils, only: [get_enablement_for_cset: 1]

  def ids(conn, _params = %{"csid" => csid,
                            "file" => ids_file}) do
    csid
    |> get_enablement_for_cset
    |> ids_with_enablement(conn, ids_file)
  end

  def ids(conn, params = %{"file" => _ids_file}) do
    ids(conn, Map.merge(params, %{"csid" => :invalid}))
  end

  def ids(conn, _params) do
    json(conn, %{"error" => ["malformed request"]})
  end


  defp ids_with_enablement(enablement, conn, ids_file) do
    team = conn.assigns[:authed_team]

    json(conn,
         Teaminterface.Ids.upload(enablement, team, ids_file))
  end
end
