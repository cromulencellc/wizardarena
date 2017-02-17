defmodule Teaminterface.DownloadController do
  use Teaminterface.Web, :controller

  import Teaminterface.DownloadUtils

  alias Teaminterface.Replacement
  alias Teaminterface.Firewall

  def cb(conn, _params = %{"team_id" => team_id,
                           "cb_id" => cb_id}) do

    [filename, digest, _timestamp] = cb_id
    |> String.reverse
    |> String.split("_", parts: 3)
    |> Enum.reverse
    |> Enum.map(&String.reverse/1)

    replacement = Replacement.from_team_filename_and_digest(team_id,
                                                            filename,
                                                            digest)

    conn |> serve(replacement, cb_id)
  end

  def ids(conn, _params = %{"team_id" => team_id,
                            "ids_id" => ids_id}) do
    [shortname, digest, _timestamp] = ids_id
    |> String.replace_suffix(".ids", "")
    |> String.reverse
    |> String.split("_", parts: 3)
    |> Enum.reverse
    |> Enum.map(&String.reverse/1)

    firewall = Firewall.from_team_and_digest(team_id, digest)

    conn |> serve(firewall, ids_id)
  end
end
