defmodule PmToolWeb.ProjectsComponent do
  use PmToolWeb, :live_component

  alias PmTool.Projects
  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <span class="font-semibold uppercase float-right text-gray-400">Projects</span>
      <%= for project <- @projects do %>
        <.live_component
          module={PmToolWeb.ProjectComponent}
          id={"project-#{project.slug}"}
          project={project}
          current_user={@current_user}
        />
      <% end %>
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
