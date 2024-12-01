defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view
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
    <div class="text-left w-80">
      <%= if @task do %>
        <.live_component module={PmToolWeb.TaskComponents} task={@task} id={"task-"<>@task.slug} expanded={true} />
      <% end %>


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
            <.live_component module={PmToolWeb.TaskComponents} id={"task-"<>task.slug} task={task} />
          <% end %>
        </ul>
      <% end %>
      <.live_component module={PmToolWeb.TaskComponents} id="new_task" current_user={@current_user} />

    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      assign(socket, id: "tasks")
      |> assign(new_task_id: "new_task")
      |> maybe_get_current_task(params)
      |> maybe_get_tasks_for_current_user()
    {:ok, socket}
  end

  def handle_event("delete_tasks", params, socket) do
    current_user = socket.assigns.current_user
    task_slugs = params["task_slugs"]
    Tasks.delete_tasks_with_slugs(current_user, task_slugs)
    socket = maybe_get_tasks_for_current_user(socket)
    {:noreply, socket}
  end

  def handle_event("move_task", %{"action" => action, "active_task_slug" => active_task_slug, "affected_task_slug" => affected_task_slug} = params, socket) do
    task = Tasks.get_task_by_slug!(active_task_slug)
    affected_task = Tasks.get_task_by_slug!(affected_task_slug)
    case action do
      "move_above" -> Tasks.move_task_above(task, affected_task)
      "move_below" -> Tasks.move_task_below(task, affected_task)
    end
    socket = maybe_get_tasks_for_current_user(socket)
    {:noreply, socket}
  end

  def handle_info({:new_task_created, new_task_id}, socket) do
    socket = 
      assign(socket, new_task_id: new_task_id) 
      |> maybe_get_tasks_for_current_user()
    {:noreply, socket}
  end

  defp maybe_get_current_task(socket, params) do
    case params["slug"] do
      nil -> assign(socket, task: nil)
      slug -> task = Tasks.get_task_by_slug!(slug)
              assign(socket, task: task)
    end
  end

  defp maybe_get_tasks_for_current_user(socket) do
    current_user = socket.assigns.current_user
    tasks = PmTool.Tasks.list_tasks_for(current_user)
    assign(socket, tasks: tasks)
  end
end
