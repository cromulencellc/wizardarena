defmodule Teaminterface.EnablementControllerTest do
  use Teaminterface.ConnCase

  alias Teaminterface.Enablement
  @valid_attrs %{round_id: 1, challenge_set_id: 1}
  @invalid_attrs %{challenge_set_id: 0}

  test "lists all entries on index", %{conn: conn} do
    _enablement = insert(:enablement)
    conn = get conn, enablement_path(conn, :index)
    assert html_response(conn, 200)
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, enablement_path(conn, :new)
    assert html_response(conn, 200) =~ "New enablement"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    valid_attrs = %{
      round_id: insert(:round).id,
      challenge_set_id: insert(:challenge_set).id
    }
    conn = post conn, enablement_path(conn, :create), enablement: valid_attrs
    assert redirected_to(conn) == enablement_path(conn, :index)
    assert Repo.get_by(Enablement, valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, enablement_path(conn, :create), enablement: @invalid_attrs
    assert html_response(conn, 200) =~ "New enablement"
  end

  test "shows chosen resource", %{conn: conn} do
    enablement = insert(:enablement)
    conn = get conn, enablement_path(conn, :show, enablement)
    assert html_response(conn, 200) =~ "Show enablement"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, enablement_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    enablement = insert(:enablement)
    conn = get conn, enablement_path(conn, :edit, enablement)
    assert html_response(conn, 200) =~ "Edit enablement"
  end

  # test "updates chosen resource and redirects when data is valid", %{conn: conn} do
  #   enablement = insert(:enablement)
  #   conn = put conn, enablement_path(conn, :update, enablement), enablement: @valid_attrs
  #   assert redirected_to(conn) == enablement_path(conn, :show, enablement)
  #   assert Repo.get_by(Enablement, @valid_attrs)
  # end

  # test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
  #   enablement = insert(:enablement)
  #   conn = put conn, enablement_path(conn, :update, enablement), enablement: @invalid_attrs
  #   assert html_response(conn, 200) =~ "Edit enablement"
  # end

  test "deletes chosen resource", %{conn: conn} do
    enablement = insert(:enablement)
    conn = delete conn, enablement_path(conn, :delete, enablement)
    assert redirected_to(conn) == enablement_path(conn, :index)
    refute Repo.get(Enablement, enablement.id)
  end
end
