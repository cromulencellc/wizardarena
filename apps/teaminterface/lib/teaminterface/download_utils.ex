defmodule Teaminterface.DownloadUtils do
  import Plug.Conn

  alias Teaminterface.Firewall
  alias Teaminterface.Replacement
  alias Teaminterface.Round

  def serve(conn, nil, _filename) do
    conn |> send_resp(404, "not found")
  end

  def serve(conn, %Replacement{} = replacement, filename) do
    conn
    |> put_resp_content_type("application/x-executable")
    |> put_resp_header("content-disposition",
                       "attachment; filename=#{filename}")
    |> send_file(200, path(replacement))
  end

  def serve(conn, %Firewall{} = firewall, filename) do
    conn
    |> put_resp_content_type("application/x-ids")
    |> put_resp_header("content-disposition",
                       "attachment; filename=#{filename}.ids")
    |> send_file(200, path(firewall))
  end

  def download_root do
    Application.get_env(:teaminterface, :download_root)
  end

  def upload_root do
    Application.get_env(:teaminterface, :upload_root)
  end

  def path(replacement = %Replacement{round: %Round{
                                         started_at: st,
                                         finished_at: fi}})
  when not is_nil(st) and is_nil(fi) do
    "~s/incoming/~B/rcb/~s"
    |> :io_lib.format([download_root,
                       replacement.team_id,
                       Replacement.filename(replacement)])
    |> IO.chardata_to_string
  end

  def path(replacement = %Replacement{}) do
    "~s/rounds/~B/~B/rcb/~s"
    |> :io_lib.format([download_root,
                       replacement.round_id,
                       replacement.team_id,
                       Replacement.filename(replacement)])
    |> IO.chardata_to_string
  end

  def path(firewall = %Firewall{round: %Round{
                                  started_at: st,
                                  finished_at: fi}})
  when not is_nil(st) and is_nil(fi) do
    "~s/incoming/~B/ids/~B.ids"
    |> :io_lib.format([upload_root,
                       firewall.team_id,
                       firewall.challenge_set_id])
    |> IO.chardata_to_string
  end

  def path(firewall = %Firewall{}) do
    "~s/rounds/~B/~B/ids/~B.ids"
    |> :io_lib.format([download_root,
                       firewall.round_id,
                       firewall.team_id,
                       firewall.challenge_set_id])
    |> IO.chardata_to_string
  end
end
