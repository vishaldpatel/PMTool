defmodule PmToolWeb.PageController do
  use PmToolWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end

  def pricing(conn, _params) do
    if PmTool.Accounts.billing_enabled?() do
      render(conn, :pricing, layout: false)
    else
      conn
      |> put_status(:not_found)
      |> put_view(PmToolWeb.ErrorHTML)
      |> render(:"404")
    end
  end
end
