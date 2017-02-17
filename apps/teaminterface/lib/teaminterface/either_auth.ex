defmodule Teaminterface.EitherAuth do
  alias Plug.Conn
  def init(options) do
    options
  end

  def call(conn = %Conn{scheme: :https}, options) do
    Teaminterface.AdminAuth.call(conn, options)
  end

  def call(conn = %Conn{assigns: %{conn_test: true}}, options) do
    Teaminterface.AdminAuth.call(conn, options)
  end

  def call(conn, options) do
    Teaminterface.BasicAuth.call(conn, options)
  end
end
