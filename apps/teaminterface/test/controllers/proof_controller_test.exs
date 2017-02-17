defmodule Teaminterface.ProofControllerTest do
  use Teaminterface.ConnCase

  @valid_attrs %{digest: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, proof_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing proofs"
  end

  test "shows chosen resource", %{conn: conn} do
    proof = insert(:proof)
    conn = get conn, proof_path(conn, :show, proof)
    assert html_response(conn, 200) =~ "Show proof"
  end

  # test "renders page not found when id is nonexistent", %{conn: conn} do
  #   assert_error_sent 404, fn ->
  #     get conn, proof_path(conn, :show, -1)
  #   end
  # end
end
