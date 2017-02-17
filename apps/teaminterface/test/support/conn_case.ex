defmodule Teaminterface.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  imports other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias Teaminterface.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]

      import Teaminterface.Router.Helpers
      import Teaminterface.Factory

      # The default endpoint for testing
      @endpoint Teaminterface.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Teaminterface.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Teaminterface.Repo, {:shared, self()})
    end

    team = Teaminterface.Factory.insert(:team) # password: "wizard arena"
    team_auth = Base.encode64("#{team.shortname}:wizard arena")

    conn = Phoenix.ConnTest.build_conn()
    |> Plug.Conn.put_req_header("authorization", "Basic #{team_auth}")
    |> Plug.Conn.assign(:conn_test, true)

    {:ok, conn: conn, team: team}
  end
end
