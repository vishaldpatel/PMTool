defmodule PmToolWeb.SearchComponent do
  use PmToolWeb, :live_component

  alias PmTool.Tasks

  def mount(socket) do
    {:ok, assign(socket, query: nil)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    """
  end
end
