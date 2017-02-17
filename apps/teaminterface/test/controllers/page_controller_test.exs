defmodule Teaminterface.PageControllerTest do
  use Teaminterface.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert redirected_to(conn) =~ "/u"
  end
end
