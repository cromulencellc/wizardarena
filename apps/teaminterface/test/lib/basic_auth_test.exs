defmodule Teaminterface.BasicAuthTest do
  use ExUnit.Case
  use Plug.Test

  alias Teaminterface.BasicAuth
  doctest BasicAuth

  @opts BasicAuth.init(realm: "wizard arena")

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Teaminterface.Repo)

    {:ok,
     team: Teaminterface.Factory.insert(:team)}
  end

  test "no auth data", _ctx do
    result = conn(:get, "/")
    |> BasicAuth.call(@opts)

    assert result.halted == true
    assert result.status == 401
    assert result.resp_body == "401 Unauthorized"
  end

  test "wrong team name", _ctx do
    auth_str = Base.encode64("wrongo:whatever")

    result = conn(:get, "/")
    |> put_req_header("authorization", "Basic #{auth_str}")
    |> BasicAuth.call(@opts)

    assert result.halted == true
    assert result.status == 401
    assert result.resp_body == "401 Unauthorized"
  end

  test "team with correct password", _ctx = %{team: team} do
    auth_str = Base.encode64("#{team.shortname}:wizard arena")

    result = conn(:get, "/")
    |> put_req_header("authorization", "Basic #{auth_str}")
    |> BasicAuth.call(@opts)

    assert result.halted == false
    assert result.state == :unset
    refute result.resp_body
    assert result.assigns[:authed_team] == team
  end

  test "team with incorrect password", _ctx = %{team: team} do
    auth_str = Base.encode64("#{team.shortname}:wrongo")

    result = conn(:get, "/")
    |> put_req_header("authorization", "Basic #{auth_str}")
    |> BasicAuth.call(@opts)

    assert result.halted == true
    assert result.status == 401
    assert result.resp_body == "401 Unauthorized"
  end
end
