defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view

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
    <div id="tasks" class="flex overflow-x-auto flex-l h-screen">
      <.live_component module={PmToolWeb.BacklogComponent} id="backlog" current_user={@current_user}, tasks={@backlog_tasks} />
      <.live_component module={PmToolWeb.UpcomingTasksComponent} id="upcoming" current_user={@current_user}, tasks={@upcoming_tasks} />
      <.live_component module={PmToolWeb.CurrentTasksComponent} id="current" current_user={@current_user}, tasks={@current_tasks} />
      <.live_component module={PmToolWeb.DoneTasksComponent} id="done" current_user={@current_user}, tasks={@done_tasks} />
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      get_tasks(socket)
    socket =
      case params["slug"] do
           nil -> assign(socket, task: nil)
           slug -> task = Tasks.get_task_by_slug!(slug)
                   assign(socket, task: task)
         end
    {:ok, socket}
  end

  defp get_tasks(socket) do
    tasks = Tasks.list_tasks_for(socket.assigns.current_user)
    assign(socket,
      backlog_tasks: Enum.filter(tasks, fn task -> task.stage == "backlog" end),
      current_tasks: Enum.filter(tasks, fn task -> task.stage == "current" end),
      upcoming_tasks: Enum.filter(tasks, fn task -> task.stage == "upcoming" end),
      done_tasks: Enum.filter(tasks, fn task -> task.stage == "done" end)
    )
  end

  def handle_info({:new_task_created}, socket) do
    socket = get_tasks(socket)
    {:noreply, socket}
  end

  def handle_info({:task_updated, task}, socket) do
    socket = 
      assign(socket, task: task) 
      |> get_tasks()
    {:noreply, socket}
  end

  def handle_event("delete_tasks", params, socket) do
    current_user = socket.assigns.current_user
    task_slugs = params["task_slugs"]
    Tasks.delete_tasks_with_slugs(current_user, task_slugs)

    socket = get_tasks(socket)
    {:noreply, socket}
  end


  def handle_event("move_task", %{"action" => action, "active_task_slug" => active_task_slug, "affected_task_slug" => affected_task_slug} = _params, socket) do
    task = Tasks.get_task_by_slug!(active_task_slug)
    affected_task = Tasks.get_task_by_slug!(affected_task_slug)
    case action do
      "move_above" -> Tasks.move_task_above(task, affected_task)
      "move_below" -> Tasks.move_task_below(task, affected_task)
    end
    {:noreply, socket}
  end

end
