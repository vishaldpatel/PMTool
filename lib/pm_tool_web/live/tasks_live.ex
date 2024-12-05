defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view

  alias PmTool.Tasks

  def render(assigns) do
    ~H"""
    <div id="tasks" class="flex overflow-x-auto h-screen">
      <.live_component module={PmToolWeb.DoneTasksComponent} id="done" current_user={@current_user} tasks={@done_tasks} />
      <.live_component module={PmToolWeb.NowAndNextTasksComponent} id="now_and_next" current_user={@current_user} tasks={@current_tasks} />
      <.live_component module={PmToolWeb.LaterTasksComponent} id="later" current_user={@current_user} tasks={@later_tasks} />
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
      later_tasks: Enum.filter(tasks, fn task -> task.stage == "Later" end),
      current_tasks: Enum.filter(tasks, fn task -> task.stage == "Now" end),
      done_tasks: Enum.filter(tasks, fn task -> task.stage == "Done" end)
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
