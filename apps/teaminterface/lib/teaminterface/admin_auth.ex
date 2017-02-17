defmodule Teaminterface.AdminAuth do
  alias Plug.Conn
  def init(options) do
    options
  end

  def call(conn = %Conn{scheme: :https}, _options) do
    conn
    |> become(conn.params)
    |> Conn.assign(:admin, true)
  end

  def call(conn = %Conn{assigns: %{conn_test: true}}, _options) do
    conn
    |> Conn.assign(:authed_team,
                   %Teaminterface.Team{shortname: "admin",
                                       name: "Administration",
                                       id: -1})
    |> Conn.assign(:admin, true)
  end

  def call(conn, _options) do
    conn
    |> Conn.send_resp(401, "401 Unauthorized")
    |> Conn.halt
  end

  defp become(conn, _params = %{"become" => team_id}) do
    team = Teaminterface.Team
    |> Teaminterface.Repo.get(String.to_integer(team_id))

    conn
    |> Conn.assign(:authed_team, team)
  end

  defp become(conn, _params) do
    conn
    |> Conn.assign(:authed_team,
                   %Teaminterface.Team{shortname: "admin",
                                       name: "Administration",
                                       id: -1})
  end
end
