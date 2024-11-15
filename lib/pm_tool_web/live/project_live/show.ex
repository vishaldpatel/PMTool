defmodule PmToolWeb.ProjectLive.Show do
  use PmToolWeb, :live_view

  alias PmTool.Projects
  alias PmTool.Tasks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"combo_slug" => combo_slug}, _, socket) do
    project = Projects.get_project!(combo_slug)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:project, project)
     |> assign(:tasks, Tasks.list_tasks_for_project(project))}
  end

  # We will handle the following events:
  # Reorder tasks
  # Expand a task
  # Collapse a task
  # Create a task
  # Edit task
  # Update a task
  # Delete a task

  defp page_title(:show), do: "Show Project"
end
