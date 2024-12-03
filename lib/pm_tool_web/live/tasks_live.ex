defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view

  def render(assigns) do
    # Renders all the components
    # Menu on the left
    # Done Tasks if toggled
    # Current Tasks
    # Upcoming Tasks if toggled
    # Backlog Tasks if toggled

    ## Placeholder:
    ~H"""
    <.live_component module={PmToolWeb.BacklogComponent} id="backlog" current_user={@current_user} />
    """
  end

  def mount(params, _session, socket) do
    socket = case params["slug"] do
      nil -> assign(socket, task: nil)
      slug -> task = Tasks.get_task_by_slug!(slug)
              assign(socket, task: task)
    end

    {:ok, socket}
  end
end
