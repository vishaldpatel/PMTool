defmodule PmToolWeb.ProjectLive.Index do
  use PmToolWeb, :live_view

  alias PmTool.Projects
  alias PmTool.Projects.Project

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :projects, Projects.list_projects())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({PmToolWeb.ProjectLive.NewFormComponent, {:created, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, %Project{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Projects")
    |> assign(:project, nil)
  end
end
