defmodule PmToolWeb.ProjectLive.Edit do
  use PmToolWeb, :live_view

  alias PmTool.Projects
  alias PmTool.Projects.Project

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"combo_slug" => combo_slug}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:project, Projects.get_project!(combo_slug))}
  end

  @impl true
  def handle_event("delete", %{"combo_slug" => combo_slug}, socket) do
    project = Projects.get_project!(combo_slug)
    {:ok, _} = Projects.delete_project(project)

    {:noreply,
    socket
    |> put_flash(:info, "Project (#{project.name}) deleted successfully")
    |> push_redirect(to: ~p"/projects")}
  end

  @impl true
  def handle_info({PmToolWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end

  defp page_title(:edit), do: "Project Settings"
end
