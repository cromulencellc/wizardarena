defmodule Teaminterface.BasicAuth do
  alias Plug.Conn

  def init(options) do
    options
  end

  def call(conn = %Conn{}, options) do
    case Conn.get_req_header(conn, "authorization") do
      ["Basic " <> encoded_auth_str] ->
        authenticate(encoded_auth_str, conn, options)
      _ -> reject(conn)
    end
  end

  defp authenticate(encoded_auth_str, conn, options)
  when is_binary(encoded_auth_str) do
    case Base.decode64(encoded_auth_str) do
      {:ok, auth_data} ->
        auth_data
        |> String.split(":")
        |> authenticate(conn, options)
        _ -> reject(conn)
    end
  end

  defp authenticate([teamname, password], conn, options) do
    team = get_team(teamname)
    case check_password(team, password) do
      true ->
        conn
        |> Conn.assign(:authed_team, team)
      false -> reject(conn)
    end
  end

  defp get_team(teamname) do
    Teaminterface.Team
    |> Teaminterface.Repo.get_by(shortname: teamname)
  end

  defp check_password(nil, _password) do
    Comeonin.Bcrypt.dummy_checkpw
    false
  end

  defp check_password(%Teaminterface.Team{password_digest: digest}, password) do
    Comeonin.Bcrypt.checkpw(password, digest)
  end

  defp reject(conn) do
    conn
    |> Conn.put_resp_header("www-authenticate",
                            "Basic realm=\"#{realm_name}\"")
    |> Conn.send_resp(401, "401 Unauthorized")
    |> Conn.halt
  end

  defp realm_name do
    Application.get_env(:teaminterface,
                        Teaminterface.Web,
                        %{contest: "Wizard Arena"})[:contest]
  end
end
