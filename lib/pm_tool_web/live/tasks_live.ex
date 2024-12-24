defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view

  alias PmTool.Tasks
  alias PmTool.Projects
  alias PmTool.Accounts

  def render(assigns) do
    ~H"""
    <div id="tasks" class="flex overflow-x-auto h-screen">
      <.live_component
        module={PmToolWeb.ProjectsComponent}
        id="projects"
        current_user={@current_user}
        new_project_id={@new_project_id}
        projects={@projects}
        open_projects={@open_projects}
      />
      <%= for project <- Projects.get_projects!(@open_projects) do %>
        <.live_component
          module={PmToolWeb.ProjectTasksComponent}
          id={"project-#{project.slug}"}
          current_user={@current_user}
          project={project}
          tasks={@open_project_tasks[project.slug]}
          timestamp={@timestamp}
        />
      <% end %>
      <%= for tag <- @open_tags do %>
        <.live_component
          module={PmToolWeb.TagTasksComponent}
          id={"tag-#{tag}"}
          current_user={@current_user}
          tag={tag}
          tasks={@open_tag_tasks[tag]}
          timestamp={@timestamp}
        />
      <% end %>
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
      socket
      |> assign(user_preferences: Accounts.get_preferences(socket.assigns.current_user))

    socket =
      socket
      |> assign(open_projects: socket.assigns.user_preferences["open_projects"] || [])
      |> assign(open_tags: socket.assigns.user_preferences["open_tags"] || [])
      |> assign(open_project_tasks: %{})
      |> assign(open_tag_tasks: %{})
      |> get_tasks()
      |> assign_new_task_ids()
      |> assign(
        merge_now_and_next_tasks:
          case socket.assigns.user_preferences["merge_now_and_next_tasks"] do 
              false -> false; 
              _ -> true 
          end
      )
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
    tasks = Tasks.list_tasks(socket.assigns.current_user)
    now_tasks = tasks[:Now]
    next_tasks = tasks[:Next]
    later_tasks = tasks[:Later]
    done_tasks = tasks[:Done]

    socket =
      Enum.reduce(socket.assigns.open_tags, socket, fn tag, socket ->
        tag_tasks = Tasks.list_tasks_for_tag(socket.assigns.current_user, tag)

        assign(socket,
          open_tag_tasks:
            Map.put(socket.assigns.open_tag_tasks, tag, tag_tasks)
        )
      end)

    socket =
      Enum.reduce(socket.assigns.open_projects, socket, fn project_slug, socket ->
        project_tasks = Tasks.list_tasks(socket.assigns.current_user, project_slug)

        assign(socket,
          open_project_tasks:
            Map.put(socket.assigns.open_project_tasks, project_slug, project_tasks)
        )
      end)

    assign(socket,
      done_tasks: done_tasks,
      now_tasks: now_tasks,
      next_tasks: next_tasks,
      later_tasks: later_tasks
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
    {:noreply,
     socket
     |> assign(project: project)
     |> get_tasks()
     |> get_projects()}
  end

  def handle_info({:new_task_created}, socket) do
    {:noreply,
     socket
     |> get_tasks()
     |> assign_new_task_ids()
     |> assign_new_project_id()}
  end

  def handle_info({:task_updated, task}, socket) do
    {:noreply,
     socket
     |> assign(task: task)
     |> get_tasks()}
  end

  defp show_tasks_with_tag(socket, tag) do
    unless Enum.member?(socket.assigns.open_tags, tag) do
      Accounts.set_preference(
        socket.assigns.current_user,
        "open_tags",
        [tag | socket.assigns.open_tags]
      )

      {:noreply,
       socket
       |> assign(open_tags: [tag | socket.assigns.open_tags])
       |> get_tasks()}
    else
      {:noreply, socket}
    end
  end

  defp hide_tasks_with_tag(socket, tag) do
    Accounts.set_preference(
      socket.assigns.current_user,
      "open_tags",
      List.delete(socket.assigns.open_tags, tag)
    )

    {:noreply,
     socket
     |> assign(open_tags: List.delete(socket.assigns.open_tags, tag))
     |> assign(open_tag_tasks: Map.delete(socket.assigns.open_tag_tasks, tag))
    }
  end

  defp show_project(socket, project_slug) do
    unless Enum.member?(socket.assigns.open_projects, project_slug) do
      Accounts.set_preference(
        socket.assigns.current_user,
        "open_projects",
        [project_slug | socket.assigns.open_projects]
      )

      {:noreply,
       socket
       |> assign(open_projects: [project_slug | socket.assigns.open_projects])
       |> get_tasks()}
    else
      {:noreply, socket}
    end
  end

  defp hide_project(socket, project_slug) do
    Accounts.set_preference(
      socket.assigns.current_user,
      "open_projects",
      List.delete(socket.assigns.open_projects, project_slug)
    )

    {:noreply,
     socket
     |> assign(open_projects: List.delete(socket.assigns.open_projects, project_slug))
     |> assign(open_project_tasks: Map.delete(socket.assigns.open_project_tasks, project_slug))
    }
  end

  def handle_event("show_project_tasks", params, socket) do
    show_project(socket, params["project_slug"])
  end

  def handle_event("hide_project_tasks", params, socket) do
    hide_project(socket, params["project_slug"])
  end

  def handle_event("hide_tag_tasks", params, socket) do
    hide_tasks_with_tag(socket, params["tag"])
  end

  def handle_event("tag_clicked", params, socket) do
    case params["tag-type"] do
      "project" -> 
        project = Projects.get_project_by_tag!(params["tag"])
        show_project(socket, project.slug)
      "task" ->
        show_tasks_with_tag(socket, params["tag"])
    end
  end

  def handle_event("separate_now_and_next_tasks", _params, socket) do
    Accounts.set_preference(
      socket.assigns.current_user,
      "merge_now_and_next_tasks",
      false
    )
    {:noreply,
     socket
     |> get_tasks()
     |> assign(merge_now_and_next_tasks: false)}
  end

  def handle_event("merge_now_and_next_tasks", _params, socket) do
    Accounts.set_preference(
      socket.assigns.current_user,
      "merge_now_and_next_tasks",
      true
    )
    {:noreply,
     socket
     |> get_tasks()
     |> assign(merge_now_and_next_tasks: true)}
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
      "estimate_task" -> Tasks.estimate_task(task, params["estimate"])
    end

    {:noreply, get_tasks(socket)}
  end

  def handle_event("delete_tasks", params, socket) do
    current_user = socket.assigns.current_user
    task_slugs = params["task_slugs"]
    Tasks.delete_tasks_with_slugs(current_user, task_slugs)

    {:noreply, get_tasks(socket)}
  end

  def handle_event("remove_tasks_from_project", params, socket) do
    project = Projects.get_project_by_slug!(params["project_slug"])
    task_slugs = params["task_slugs"]

    Enum.each(task_slugs, fn task_slug ->
      task = Tasks.get_task_by_slug!(task_slug)
      Tasks.update_task(task, %{project_tags: List.delete(task.project_tags, project.tag)})
    end)

    {:noreply, get_tasks(socket)}
  end

  def handle_event(
        "move_task",
        %{
          "task_slug" => task_slug,
          "target_project_slug" => project_slug
        } = _params,
        socket
      ) do
    task = Tasks.get_task_by_slug!(task_slug)
    project = Projects.get_project_by_slug!(project_slug)

    unless Enum.member?(task.project_tags, project.tag) do
      Tasks.update_task(task, %{project_tags: [project.tag | task.project_tags]})
    end

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
