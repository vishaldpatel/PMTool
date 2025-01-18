defmodule PmToolWeb.ProjectsComponent do
  use PmToolWeb, :live_component

  alias PmTool.Projects
  alias PmTool.Projects.Project
  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div>
      <button
        class="font-bold rounded"
        title="Start New Project"
        phx-click={JS.toggle_class("hidden", to: "#edit-" <> @new_project_id)}
      >
        <svg
          class="h-6 w-6 text-cyan-500 hover:text-cyan-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Projects</span>

      <%= if @projects do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for project <- @projects do %>
            <.live_component
              module={PmToolWeb.ProjectComponent}
              id={"project-#{project.slug}"}
              project={project}
              current_user={@current_user}
              open_project_slugs={@open_project_slugs}
              timestamp={@timestamp}
              project_progress={
                if @project_progress[project.tag] do
                  @project_progress[project.tag]
                else
                  0.0
                end
              }
            />
          <% end %>
        </ul>
      <% end %>
      <.live_component
        module={PmToolWeb.ProjectComponent}
        id={@new_project_id}
        current_user={@current_user}
        project={%Project{}}
      />
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       open_project_slugs: []
     )}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> maybe_get_current_project()

    {:ok, socket}
  end

  defp maybe_get_current_project(socket) do
    case socket.assigns["slug"] do
      nil ->
        assign(socket, project: nil)

      slug ->
        project = Projects.get_project_by_slug!(slug)
        assign(socket, project: project)
    end
  end
end
