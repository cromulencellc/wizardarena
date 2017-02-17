defmodule Teaminterface.PageController do
  use Teaminterface.Web, :controller

  def index(conn, _params) do
    redirect conn, to: dashboard_path(conn, :index)
  end
end
