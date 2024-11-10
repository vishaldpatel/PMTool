defmodule PmToolWeb.ProjectLive.Show do
  use PmToolWeb, :live_view

  alias PmTool.Projects

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

  defp page_title(:show), do: "Show Project"
end
