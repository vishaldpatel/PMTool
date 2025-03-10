defmodule PmToolWeb.PageController do
  use PmToolWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
  
  def privacy(conn, _params) do
    render(conn, :privacy, layout: false)
  end

  def tos(conn, _params) do
    render(conn, :tos, layout: false)
  end
end
