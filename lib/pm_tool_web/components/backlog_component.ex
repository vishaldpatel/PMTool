defmodule PmToolWeb.BacklogComponent do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks

  def render(assigns) do
    # Renders all the components
    # Menu on the left
    # Done Tasks if toggled
    # Current Tasks
    # Upcoming Tasks if toggled
    # Backlog Tasks if toggled

    ## Placeholder:
    ~H"""
    <div class="mr-2 float-left text-left w-80 flex-shrink-0">
      <span class="font-semibold uppercase float-right text-gray-400">Backlog</span>

      <button 
        class="font-bold rounded" 
        phx-click={
          JS.toggle(to: "#edit-"<>@new_task_id)
        }>
        <svg class="h-6 w-6 text-cyan-500"  fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
        </svg>
      </button>

      <form id="batch_task_options" style="display: none;" phx-submit="delete_tasks">
        <button class="font-bold rounded">
          <svg class="h-6 w-6 text-red-500"  width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">  <path stroke="none" d="M0 0h24v24H0z"/>  <line x1="4" y1="7" x2="20" y2="7" />  <line x1="10" y1="11" x2="10" y2="17" />  <line x1="14" y1="11" x2="14" y2="17" />  <path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" />  <path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></svg> 
        </button>
      </form>
      <%= if @tasks do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for task <- @tasks do %>
            <.live_component module={PmToolWeb.TaskComponents} id={"task-#{task.slug}#{@timestamp}"} task={task} />
          <% end %>
        </ul>
      <% end %>
      <.live_component module={PmToolWeb.TaskComponents} id={@new_task_id} current_user={@current_user} />
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    timestamp = DateTime.to_unix(DateTime.utc_now())
    new_task_id = "new-backlog-task-#{timestamp}"

    socket =
      socket
      |> assign(assigns)
      |> assign(timestamp: DateTime.to_unix(DateTime.utc_now()))
      |> assign(new_task_id: new_task_id)
      |> maybe_get_current_task()
      |> assign(tasks: assigns.tasks)
    {:ok, socket}
  end

  def get_backlog_tasks(socket) do
    assign(socket, tasks: Tasks.list_tasks_for(socket.assigns.current_user, "backlog"))
  end

  defp maybe_get_current_task(socket) do
    case socket.assigns["slug"] do
      nil -> assign(socket, task: nil)
      slug -> task = Tasks.get_task_by_slug!(slug)
              assign(socket, task: task)
    end
  end
end
