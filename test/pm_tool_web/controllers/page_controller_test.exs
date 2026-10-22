defmodule PmToolWeb.PageControllerTest do
  use PmToolWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Get it done. One week at a time."
  end

  test "GET /pricing is not found when billing is disabled", %{conn: conn} do
    conn = get(conn, ~p"/pricing")
    assert html_response(conn, 404)
  end
end
