defmodule Teaminterface.UploadControllerTest do
  use Teaminterface.ConnCase
  import Teaminterface.ConnCase.Fixture

  # more tests in test/controllers/upload_controller/ directory

  test "POST without csid", %{conn: conn} do
    resp = conn
    |> post("/rcb",
            %{'LUNGE_00001' => fixture("LUNGE_00001.cgc")})
    |> json_response(200)

    assert resp ==
      %{"error" => ["invalid csid"]}
  end
end
