defmodule PmToolWeb.ProjectComponent do
  use PmToolWeb, :live_component


  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80">
      <h2 class="text-2xl font-bold mb-2"><%= @project.name %></h2>
      <p class="text-gray-600"><%= @project.description %></p>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
    {:ok, socket}
  end

end
