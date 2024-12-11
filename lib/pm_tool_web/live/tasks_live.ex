defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view

  alias PmTool.Tasks
  alias PmTool.Projects

  def render(assigns) do
    ~H"""
    <div id="tasks" class="flex overflow-x-auto h-screen">
      <.live_component
        module={PmToolWeb.ProjectsComponent}
        id="projects"
        current_user={@current_user}
        new_project_id={@new_project_id}
        projects={@projects}
      />
      <%= if @merge_now_and_next_tasks do %>
        <.live_component
          module={PmToolWeb.NowAndNextTasksComponent}
          id="now_and_next"
          current_user={@current_user}
          now_tasks={@now_tasks}
          next_tasks={@next_tasks}
          new_task_id={@new_now_next_task_id}
          timestamp={@timestamp}
        />
      <% else %>
        <.live_component
          module={PmToolWeb.NowTasksComponent}
          id="now"
          current_user={@current_user}
          tasks={@now_tasks}
          new_task_id={@new_now_task_id}
          timestamp={@timestamp}
        />
        <.live_component
          module={PmToolWeb.NextTasksComponent}
          id="next"
          current_user={@current_user}
          tasks={@next_tasks}
          new_task_id={@new_next_task_id}
          timestamp={@timestamp}
        />
      <% end %>
      <.live_component
        module={PmToolWeb.LaterTasksComponent}
        id="later"
        current_user={@current_user}
        tasks={@later_tasks}
        new_task_id={@new_later_task_id}
        timestamp={@timestamp}
      />
      <.live_component
        module={PmToolWeb.DoneTasksComponent}
        id="done"
        current_user={@current_user}
        tasks={@done_tasks}
        timestamp={@timestamp}
      />
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      get_tasks(socket)
      |> assign_new_task_ids()
      |> assign(merge_now_and_next_tasks: true)
      |> get_projects()
      |> assign_new_project_id()

    socket =
      case params["slug"] do
        nil ->
          assign(socket, task: nil)

        slug ->
          task = Tasks.get_task_by_slug!(slug)
          assign(socket, task: task)
      end

    {:ok, socket}
  end

  defp get_projects(socket) do
    assign(socket, projects: Projects.list_projects_for(socket.assigns.current_user))
  end

  defp get_tasks(socket) do
    [last_task_order, now_tasks] = Tasks.list_now_tasks_for_next(socket.assigns.current_user)
    next_tasks = Tasks.list_tasks_for(socket.assigns.current_user, "Next", last_task_order)
    later_and_done_tasks = Tasks.list_tasks_for(socket.assigns.current_user, "Later+Done")

    assign(socket,
      done_tasks: Enum.filter(later_and_done_tasks, fn task -> task.stage == "Done" end),
      now_tasks: now_tasks,
      next_tasks: next_tasks,
      later_tasks: Enum.filter(later_and_done_tasks, fn task -> task.stage == "Later" end)
    )
  end

  def assign_new_project_id(socket) do
    timestamp = DateTime.to_unix(DateTime.utc_now())

    assign(socket,
      timestamp: timestamp,
      new_project_id: "new-project-#{timestamp}"
    )
  end

  def assign_new_task_ids(socket) do
    timestamp = DateTime.to_unix(DateTime.utc_now())

    assign(socket,
      timestamp: timestamp,
      new_now_task_id: "new-now-task-#{timestamp}",
      new_next_task_id: "new-next-task-#{timestamp}",
      new_now_next_task_id: "new-now-next-task-#{timestamp}",
      new_later_task_id: "new-later-task-#{timestamp}"
    )
  end

  def handle_info({:new_project_created}, socket) do
    {:noreply,
     get_projects(socket)
     |> assign_new_project_id()}
  end

  def handle_info({:project_updated, project}, socket) do
    socket =
      assign(socket, project: project)
      |> get_projects()

    {:noreply, socket}
  end

  def handle_info({:new_task_created}, socket) do
    {:noreply,
     get_tasks(socket)
     |> assign_new_project_id()}
  end

  def handle_info({:task_updated, task}, socket) do
    socket =
      assign(socket, task: task)
      |> get_tasks()

    {:noreply, socket}
  end

  def handle_event("separate_now_and_next_tasks", _params, socket) do
    socket = get_tasks(socket)
    {:noreply, assign(socket, merge_now_and_next_tasks: false)}
  end

  def handle_event("merge_now_and_next_tasks", _params, socket) do
    socket = get_tasks(socket)
    {:noreply, assign(socket, merge_now_and_next_tasks: true)}
  end

  def handle_event("task_action", params, socket) do
    task_slug = params["task_slug"]
    task = Tasks.get_task_by_slug!(task_slug)

    case params["action"] do
      "start_task" -> Tasks.start_task(task)
      "finish_task" -> Tasks.finish_task(task)
      "deliver_task" -> Tasks.deliver_task(task)
      "accept_task" -> Tasks.accept_task(task)
      "reject_task" -> Tasks.reject_task(task)
    end

    {:noreply, get_tasks(socket)}
  end

  def handle_event("delete_tasks", params, socket) do
    current_user = socket.assigns.current_user
    task_slugs = params["task_slugs"]
    Tasks.delete_tasks_with_slugs(current_user, task_slugs)

    {:noreply, get_tasks(socket)}
  end

  def handle_event(
        "move_task",
        %{
          "action" => action,
          "active_task_slug" => active_task_slug,
          "affected_task_slug" => affected_task_slug
        } = _params,
        socket
      ) do
    task = Tasks.get_task_by_slug!(active_task_slug)
    affected_task = Tasks.get_task_by_slug!(affected_task_slug)

    case action do
      "move_above" -> Tasks.move_task_above(task, affected_task)
      "move_below" -> Tasks.move_task_below(task, affected_task)
    end

    {:noreply, get_tasks(socket)}
  end
end
