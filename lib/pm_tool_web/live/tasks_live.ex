defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view

  alias PmTool.Tasks
  alias PmTool.Teams
  alias PmTool.Teams.Team
  alias PmTool.Projects
  alias PmTool.Accounts

  def render(assigns) do
    ~H"""
    <div id="tasks" class="flex overflow-x-auto h-screen">
      <div class="mr-2 text-left w-60 flex-shrink-0">
        <.live_component
          module={PmToolWeb.ProjectsComponent}
          id="projects"
          current_user={@current_user}
          new_project_id={@new_project_id}
          timestamp={@timestamp}
          projects={@projects}
          open_project_slugs={@open_project_slugs}
          project_progress={@project_progress}
        />
        <.live_component
          module={PmToolWeb.TeamsComponent}
          id="teams"
          current_user={@current_user}
          new_team_id={@new_team_id}
          teams={@teams}
          current_team={@current_team}
          open_team_slugs={@open_team_slugs}
          timestamp={@timestamp}
          show_changelog={@show_changelog}
        />
        <.live_component module={PmToolWeb.SearchTagsComponent} id="search_tags" tags={@search_tags} />
        <div class="absolute bottom-1">
          <.live_component
            module={PmToolWeb.SubscriptionComponent}
            id="subscription"
            subscription={@subscription}
            current_user={@current_user}
            action_count={@action_count}
            can_cancel={false}
          />
        </div>
      </div>
      <%= for project <- @open_projects do %>
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
          open_tasks={@open_tasks}
          timestamp={@timestamp}
        />
      <% end %>
      <%= if @show_changelog do %>
        <.live_component
          module={PmToolWeb.ChangesComponent}
          id="changelog"
          title="Changelog"
          changes={@changes}
          changes_week_number={@changes_week_number}
        />
      <% end %>
      <%= if @merge_now_and_next_tasks do %>
        <.live_component
          module={PmToolWeb.NowAndNextTasksComponent}
          id="now_and_next"
          current_user={@current_user}
          now_tasks={@tasks[:Now]}
          next_tasks={@tasks[:Next]}
          new_task_id={@new_now_next_task_id}
          open_tasks={@open_tasks}
          timestamp={@timestamp}
          current_team={@current_team}
        />
      <% else %>
        <.live_component
          module={PmToolWeb.NowTasksComponent}
          id="now"
          current_user={@current_user}
          tasks={@tasks[:Now]}
          new_task_id={@new_now_task_id}
          open_tasks={@open_tasks}
          timestamp={@timestamp}
          current_team={@current_team}
        />
        <.live_component
          module={PmToolWeb.NextTasksComponent}
          id="next"
          current_user={@current_user}
          tasks={@tasks[:Next]}
          new_task_id={@new_next_task_id}
          open_tasks={@open_tasks}
          timestamp={@timestamp}
          current_team={@current_team}
        />
      <% end %>
      <.live_component
        module={PmToolWeb.LaterTasksComponent}
        id="later"
        current_user={@current_user}
        tasks={@tasks[:Later]}
        new_task_id={@new_later_task_id}
        open_tasks={@open_tasks}
        timestamp={@timestamp}
        current_team={@current_team}
      />
      <%= if not is_nil(@done_months_ago) or 
             @tasks[:Done] |> Map.values() |> List.flatten() |> Enum.count() > 0 do %>
        <.live_component
          module={PmToolWeb.DoneTasksComponent}
          id="done"
          current_user={@current_user}
          tasks={@tasks[:Done]}
          open_tasks={@open_tasks}
          timestamp={@timestamp}
          done_months_ago={@done_months_ago}
          loading_done_tasks={@loading_done_tasks}
        />
      <% end %>
    </div>
    """
  end

  def render_empty(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-screen">
      <div class="text-center">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          xmlns:xlink="http://www.w3.org/1999/xlink"
          fill="#000000"
          height="200px"
          width="150px"
          version="1.1"
          id="Capa_1"
          viewBox="0 0 431.347 431.347"
          xml:space="preserve"
        >
          <path
            id="XMLID_47_"
            d="M60.177,103.279v-18h17.564v18H60.177z M195.34,310.388c-12.314-17.736-36.526-49.441-60.314-62.499  c-21.169-11.621-34.072-3.648-39.881,2.138l12.705,12.751c2.254-2.247,5.523-4.211,12.662-1.757  c14.05,4.827,33.989,23.833,54.706,52.146c14.808,20.237,24.831,38.142,28.947,47.45c-10.541,1.535-25.629-0.151-41.676-4.841  c-22.353-6.534-42.723-17.648-55.888-30.492c-14.992-14.627-19.483-29.964-13.35-45.585l2.325-5.92l-4.805-4.168  c-16.492-14.305-24.906-30.681-25.007-48.673l-0.41-73.931h-8.95C35.229,147.005,18,129.776,18,108.6  c0-21.176,17.229-38.405,38.405-38.405h23.701c8.845,0,14.106,7.764,14.733,15.437c0.111,1.366,0.122,3.688,0.133,6.145  c0.052,11.392,0.123,26.993,7.953,35.816l13.463-11.948c-3.324-3.745-3.389-17.903-3.416-23.949  c-0.013-2.938-0.024-5.474-0.193-7.53c-1.487-18.226-15.533-31.97-32.673-31.97H56.405C25.304,52.195,0,77.498,0,108.6  c0,28.055,20.59,51.392,47.451,55.695l0.314,56.742c0.12,21.315,9.339,41.285,26.74,58.08c-5.563,20.448,1.234,41.203,19.526,59.049  c15.206,14.835,38.316,27.551,63.407,34.885c13.872,4.055,26.937,6.101,38.207,6.101c8.977,0,16.815-1.298,23.016-3.911l4.292-1.809  l1.002-4.548c0.738-3.352,0.807-8.298-7.786-24.665C210.85,334.086,203.452,322.07,195.34,310.388z M317.151,276.567  c-9.628-3.972-23.822-6.079-34.781-0.089c-6.743,3.686-11.061,9.793-12.485,17.663l17.711,3.208  c0.447-2.467,1.498-4.032,3.406-5.076c4.243-2.319,12.354-1.926,19.286,0.934c23.851,9.838,49.97,47.685,58.715,65.336  c-21.86-0.602-56.692-9.203-74.321-24.043c-6.542-5.507-9.923-11.23-10.051-17.011l-0.151-6.817l-6.603-1.7  c-10.733-2.764-43.312-6.911-64.873,6.895l9.705,15.159c12.381-7.927,32.896-7.559,44.891-5.756  c2.028,8.324,7.215,16.035,15.49,23.001c22.309,18.779,63.577,28.252,88.795,28.251c3.884,0,7.391-0.225,10.385-0.675l6.119-0.92  l1.332-6.043c2.563-11.627-16.183-38.507-21.989-46.469C357.999,309.07,338.485,285.367,317.151,276.567z M429.473,219.554  c-9.41,31.17-31.051,56.212-68.094,78.796l-9.369-15.369c26.69-16.272,44.311-33.632,54.342-53.771  c-57.392,10.891-134.155,11.81-158.058,11.81c-55.169,0-109.044-6.086-155.803-17.602l-6.188-1.524l-0.618-6.342  c-0.305-3.128-0.459-6.282-0.459-9.372c0-33.767,17.305-65.342,48.726-88.907c30.646-22.985,71.254-35.643,114.342-35.643  c78.001,0,145.128,42.18,160.02,100.416c0.938,0.727,3.139,1.851,4.656,2.625C420.716,188.624,436.821,196.841,429.473,219.554z   M123.917,211.837c1.899-16.608,8.691-33.886,19.649-49.651c10.612-15.269,24.015-27.674,37.469-34.829V111.79  c-46.214,17.838-77.809,53.457-77.809,94.391c0,0.432,0.004,0.865,0.011,1.3C109.99,209.047,116.893,210.5,123.917,211.837z   M239.294,222.964l-0.002-51.875l-48.962-28.27c-20.266,10.445-45.607,40.264-48.656,72.106  C172.617,219.818,205.625,222.55,239.294,222.964z M297.551,127.06v-21.068c-15.683-4.175-32.345-6.362-49.257-6.362  c-17.283,0-33.874,2.232-49.259,6.324v21.107l49.257,28.44L297.551,127.06z M360.417,217.54  c-3.834-30.818-31.886-63.651-53.465-75.123l-49.66,28.672l0.002,51.894C289.097,222.728,326.513,221.115,360.417,217.54z   M404.788,200.704c-5.304-2.707-11.904-6.075-13.749-13.548c-5.905-23.911-23.124-45.881-48.484-61.865  c-8.34-5.256-17.405-9.761-27.004-13.463v14.795c25.711,13.885,58.102,50.938,62.744,88.798c12.668-1.684,24.548-3.685,35.09-6.04  C413.619,205.41,411.041,203.895,404.788,200.704z"
          />
        </svg>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    if not connected?(socket) do
      {:ok, render_with(socket, &render_empty/1)}
    else
      zero_tasks = %{
        Now: [],
        Next: %{},
        Done: %{last: [], two: [], three: [], earlier: []},
        Later: []
      }

      user_preferences = Accounts.get_preferences(current_user)
      open_project_slugs = user_preferences["open_project_slugs"] || []
      open_tags = user_preferences["open_tags"] || []
      open_tag_tasks = Enum.into(open_tags, %{}, fn tag -> {tag, zero_tasks} end)
      open_project_tasks = Enum.into(open_project_slugs, %{}, fn slug -> {slug, zero_tasks} end)

      teams = Teams.list_teams(current_user)

      current_team =
        case user_preferences["current_team_id"] do
          nil -> nil
          team_id -> Teams.get_team!(team_id)
        end

      user_velocity = Tasks.get_velocity(current_user)

      team_velocity =
        case current_team do
          nil -> nil
          current_team -> Tasks.get_velocity(current_team)
        end

      team_velocities =
        case Enum.count(teams) > 0 do
          true -> Tasks.get_velocities(teams)
          false -> {}
        end

      socket =
        socket
        |> assign(user_preferences: user_preferences)
        |> assign(open_project_slugs: open_project_slugs)
        |> assign(subscription: Accounts.get_subscription(current_user))
        |> assign(action_count: 0)
        |> assign(projects: [])
        |> assign(search_tags: [])
        |> assign(open_projects: [])
        |> assign(changes: [])
        |> assign(changes_week_number: 0)
        |> assign(open_tags: open_tags)
        |> assign(open_tasks: %{})
        |> assign(open_project_tasks: open_project_tasks)
        |> assign(open_tag_tasks: open_tag_tasks)
        |> assign(show_changelog: user_preferences["show_changelog"] || false)
        |> assign(open_team_slugs: user_preferences["open_team_slugs"] || [])
        |> assign(tasks: %{Now: [], Next: %{}, Done: %{}})
        |> assign(done_months_ago: nil)
        |> assign(project_progress: %{})
        |> assign(loading_done_tasks: false)
        |> assign(teams: teams)
        |> assign(current_team: current_team)
        |> maybe_get_current_task(params)
        |> start_async(:get_open_tag_tasks, fn ->
          get_tasks_for_tags(current_user, teams, open_tags, user_velocity, team_velocities)
        end)
        |> start_async(:get_open_project_tasks, fn ->
          get_tasks_for_open_projects(
            current_user,
            current_team,
            teams,
            open_project_slugs,
            user_velocity,
            team_velocity,
            team_velocities
          )
        end)
        |> start_async(:get_main_tasks, fn ->
          get_now_next_later_and_done_tasks(
            current_user,
            current_team,
            teams,
            user_velocity,
            team_velocity,
            team_velocities
          )
        end)
        |> start_async(:get_projects, fn -> Projects.list_projects_for(current_user) end)
        |> start_async(:get_open_projects, fn -> Projects.get_projects!(open_project_slugs) end)
        |> assign(
          merge_now_and_next_tasks:
            case user_preferences["merge_now_and_next_tasks"] do
              false -> false
              _ -> true
            end
        )
        |> start_async(:get_search_tags, fn -> Tasks.list_tags(current_user, teams) end)
        |> get_changes()
        |> assign_new_project_id()
        |> assign_new_team_id()
        |> assign_new_task_ids()
        |> assign(
          task:
            case params["slug"] do
              nil -> nil
              slug -> Tasks.get_task_by_slug!(slug)
            end
        )

      {:ok, socket}
    end
  end

  def handle_async(:get_projects, {:ok, projects}, socket) do
    socket = assign(socket, projects: projects)
    {:noreply, socket}
  end

  def handle_async(:get_search_tags, {:ok, tags}, socket) do
    socket = assign(socket, search_tags: tags)
    {:noreply, socket}
  end

  def handle_async(:get_main_tasks, {:ok, tasks}, socket) do
    socket =
      socket
      |> assign(:tasks, tasks)
      |> get_project_progress()

    {:noreply, socket}
  end

  def handle_async(:get_open_tag_tasks, {:ok, open_tag_tasks}, socket) do
    socket = assign(socket, open_tag_tasks: open_tag_tasks)
    {:noreply, socket}
  end

  def handle_async(:get_open_project_tasks, {:ok, open_project_tasks}, socket) do
    socket = assign(socket, open_project_tasks: open_project_tasks)
    {:noreply, socket}
  end

  def handle_async(:get_open_projects, {:ok, open_projects}, socket) do
    socket = assign(socket, open_projects: open_projects)
    {:noreply, socket}
  end

  def handle_async(:get_changes, {:ok, {user_or_team_changes, action_count}}, socket) do
    socket =
      socket
      |> assign(changes: user_or_team_changes)
      |> assign(action_count: action_count)

    {:noreply, socket}
  end

  defp maybe_get_current_task(socket, params) do
    case params["slug"] do
      nil ->
        socket

      slug ->
        assign(socket, open_tasks: Map.put(socket.assigns.open_tasks, slug, true))
    end
  end

  defp get_teams(socket) do
    assign(socket, teams: Teams.list_teams(socket.assigns.current_user))
  end

  defp get_projects(socket) do
    socket
    |> assign(projects: Projects.list_projects_for(socket.assigns.current_user))
    |> assign(open_projects: Projects.get_projects!(socket.assigns.open_project_slugs))
  end

  defp get_project_progress(socket) do
    # For each project, get the number of tasks that are "Done" divided by the total number of tasks in the project
    all_tasks = flatten_tasks(socket.assigns.tasks)

    [done_project_tasks, total_project_tasks] =
      Enum.reduce(all_tasks, [%{}, %{}], fn task,
                                            [
                                              done_project_tasks,
                                              total_project_tasks
                                            ] ->
        Enum.reduce(task.project_tags, [done_project_tasks, total_project_tasks], fn project_tag,
                                                                                     [
                                                                                       done_project_tasks,
                                                                                       total_project_tasks
                                                                                     ] ->
          done_project_tasks =
            if Enum.member?(["Accepted", "Closed"], task.status) do
              total = done_project_tasks[project_tag] || 0
              Map.put(done_project_tasks, project_tag, total + 1)
            else
              done_project_tasks
            end

          total = total_project_tasks[project_tag] || 0
          total_project_tasks = Map.put(total_project_tasks, project_tag, total + 1)
          [done_project_tasks, total_project_tasks]
        end)
      end)

    socket
    |> assign(
      project_progress:
        Map.new(done_project_tasks, fn {k, v} -> {k, v / total_project_tasks[k] * 100} end)
    )
  end

  defp get_tasks_for_tags(user, teams, tags, user_velocity, team_velocities) do
    Enum.reduce(tags, %{}, fn tag, acc ->
      tag_tasks =
        Tasks.list_tasks_for_tag(user, teams, tag, user_velocity, team_velocities)

      Map.put(acc, tag, tag_tasks)
    end)
  end

  defp get_tasks_for_open_projects(
         user,
         team,
         teams,
         project_slugs,
         user_velocity,
         team_velocity,
         team_velocities
       ) do
    Enum.reduce(project_slugs, %{}, fn project_slug, acc ->
      project_tasks =
        case team do
          current_team = %Team{} ->
            Tasks.list_tasks(current_team, project_slug, team_velocity)

          _ ->
            Tasks.list_tasks(
              user,
              project_slug,
              teams,
              user_velocity,
              team_velocities
            )
        end

      Map.put(acc, project_slug, project_tasks)
    end)
  end

  defp flatten_tasks(tasks) do
    ((tasks[:Now] ++
        (tasks[:Next] |> Map.values() |> List.flatten())) ++
       tasks[:Later]) ++
      (tasks[:Done] |> Map.values() |> List.flatten())
  end

  defp get_now_next_later_and_done_tasks(
         user,
         team,
         teams,
         user_velocity,
         team_velocity,
         team_velocities
       ) do
    case team do
      current_team = %Team{} ->
        Tasks.list_tasks(current_team, team_velocity)

      _ ->
        Tasks.list_tasks(
          user,
          teams,
          user_velocity,
          team_velocities
        )
    end
  end

  defp get_changes(socket) do
    current_user = socket.assigns.current_user
    current_team = socket.assigns.current_team
    changes_week_number = socket.assigns.changes_week_number

    socket
    |> start_async(:get_changes, fn ->
      user_or_team_changes =
        Teams.list_changes(
          current_user,
          current_team,
          changes_week_number
        )

      user_action_count = Accounts.get_user_actions_count(current_user)
      {user_or_team_changes, user_action_count}
    end)
  end

  defp get_done_tasks(socket) do
    current_user = socket.assigns.current_user
    teams = socket.assigns.teams
    current_team = socket.assigns.current_team
    user_velocity = Tasks.get_velocity(current_user)
    done_months_ago = socket.assigns.done_months_ago

    team_velocity =
      case current_team do
        nil -> nil
        current_team -> Tasks.get_velocity(current_team)
      end

    team_velocities =
      case Enum.count(teams) > 0 do
        true -> Tasks.get_velocities(teams)
        false -> {}
      end

    done_tasks = case current_team do
      current_team = %Team{} ->
        Tasks.list_done_tasks(current_team, team_velocity, done_months_ago)

      _ ->
        Tasks.list_done_tasks(
          current_user,
          teams,
          user_velocity,
          team_velocities,
          done_months_ago
        )
      end

    socket
    |> assign(
      tasks: Map.put(socket.assigns.tasks, :Done, done_tasks[:Done])
    )
  end

  defp get_tasks(socket) do
    current_user = socket.assigns.current_user
    teams = socket.assigns.teams
    open_tags = socket.assigns.open_tags
    current_team = socket.assigns.current_team
    open_project_slugs = socket.assigns.open_project_slugs
    user_velocity = Tasks.get_velocity(current_user)

    team_velocity =
      case current_team do
        nil -> nil
        current_team -> Tasks.get_velocity(current_team)
      end

    team_velocities =
      case Enum.count(teams) > 0 do
        true -> Tasks.get_velocities(teams)
        false -> {}
      end

    socket
    |> assign(
      open_tag_tasks:
        get_tasks_for_tags(current_user, teams, open_tags, user_velocity, team_velocities)
    )
    |> assign(
      open_project_tasks:
        get_tasks_for_open_projects(
          current_user,
          current_team,
          teams,
          open_project_slugs,
          user_velocity,
          team_velocity,
          team_velocities
        )
    )
    |> assign(
      tasks:
        get_now_next_later_and_done_tasks(
          current_user,
          current_team,
          teams,
          user_velocity,
          team_velocity,
          team_velocities
        )
    )
  end

  defp assign_new_timestamp_for_ids(socket) do
    timestamp = DateTime.to_unix(DateTime.utc_now())

    assign(socket, timestamp: timestamp)
  end

  defp assign_new_team_id(socket) do
    timestamp = DateTime.to_unix(DateTime.utc_now())

    assign(socket,
      timestamp: timestamp,
      new_team_id: "new-team-#{timestamp}"
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

  def handle_info({:load_done_tasks, done_months_ago}, socket) do
    {:noreply,
      socket
      |> assign(loading_done_tasks: false)
      |> assign(done_months_ago: done_months_ago)
      |> get_done_tasks()}
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
     |> get_projects()
     |> get_project_progress()}
  end

  def handle_info({:team_member_deleted}, socket) do
    {:noreply, get_teams(socket)}
  end

  def handle_info({:team_member_updated, _team_member}, socket) do
    {:noreply, socket}
  end

  def handle_info({:new_team_member_created}, socket) do
    {:noreply,
     get_teams(socket)
     |> assign_new_timestamp_for_ids()}
  end

  def handle_info({:new_team_created}, socket) do
    {:noreply,
     get_teams(socket)
     |> assign_new_team_id()}
  end

  def handle_info({:new_task_created}, socket) do
    {:noreply,
     socket
     |> get_tasks()
     |> assign_new_task_ids()
     |> assign_new_project_id()
     |> get_changes()
     |> get_project_progress()}
  end

  def handle_info({:team_updated, team}, socket) do
    {:noreply,
     socket
     |> assign(team: team)}
  end

  def handle_info({:task_updated, task}, socket) do
    {:noreply,
     socket
     |> assign(task: task)
     |> get_tasks()
     |> get_changes()
     |> get_project_progress()}
  end

  defp show_tasks_with_tag(socket, tag) do
    open_tags = socket.assigns.open_tags || []

    if not Enum.member?(open_tags, tag) do
      Accounts.set_preference(
        socket.assigns.current_user,
        "open_tags",
        [tag | open_tags]
      )

      {:noreply,
       socket
       |> assign(open_tags: [tag | open_tags])
       |> get_tasks()}
    else
      {:noreply, socket}
    end
  end

  defp hide_tasks_with_tag(socket, tag) do
    open_tags = socket.assigns.open_tags

    Accounts.set_preference(
      socket.assigns.current_user,
      "open_tags",
      List.delete(open_tags, tag)
    )

    {:noreply,
     socket
     |> assign(open_tags: List.delete(open_tags, tag))
     |> assign(open_tag_tasks: Map.delete(socket.assigns.open_tag_tasks, tag))}
  end

  defp show_hide_team_members(socket, team_slug) do
    open_team_slugs = socket.assigns.open_team_slugs || []

    if Enum.member?(open_team_slugs, team_slug) do
      hide_team_members(socket, team_slug)
    else
      show_team_members(socket, team_slug)
    end
  end

  defp show_team_members(socket, team_slug) do
    open_team_slugs = socket.assigns.open_team_slugs || []

    Accounts.set_preference(
      socket.assigns.current_user,
      "open_team_slugs",
      [team_slug | open_team_slugs]
    )

    open_team_slugs = [team_slug | open_team_slugs]

    {:noreply,
     socket
     |> assign(open_team_slugs: open_team_slugs)}
  end

  defp hide_team_members(socket, team_slug) do
    open_team_slugs = socket.assigns.open_team_slugs

    Accounts.set_preference(
      socket.assigns.current_user,
      "open_team_slugs",
      List.delete(open_team_slugs, team_slug)
    )

    open_team_slugs = List.delete(open_team_slugs, team_slug)

    {:noreply,
     socket
     |> assign(open_team_slugs: open_team_slugs)}
  end

  defp show_project(socket, project_slug) do
    open_project_slugs = socket.assigns.open_project_slugs || []

    if not Enum.member?(open_project_slugs, project_slug) do
      Accounts.set_preference(
        socket.assigns.current_user,
        "open_project_slugs",
        [project_slug | open_project_slugs]
      )

      open_project_slugs = [project_slug | open_project_slugs]

      {:noreply,
       socket
       |> assign(open_project_slugs: open_project_slugs)
       |> assign(open_projects: Projects.get_projects!(open_project_slugs))
       |> get_tasks()}
    else
      {:noreply, socket}
    end
  end

  defp hide_project(socket, project_slug) do
    open_project_slugs = socket.assigns.open_project_slugs

    Accounts.set_preference(
      socket.assigns.current_user,
      "open_project_slugs",
      List.delete(open_project_slugs, project_slug)
    )

    open_project_slugs = List.delete(open_project_slugs, project_slug)
    open_project_tasks = socket.assigns.open_project_tasks

    {:noreply,
     socket
     |> assign(open_project_slugs: open_project_slugs)
     |> assign(open_project_tasks: Map.delete(open_project_tasks, project_slug))
     |> assign(open_projects: Projects.get_projects!(open_project_slugs))}
  end

  defp set_current_team(socket, slug) do
    team = Teams.get_team_by_slug!(slug)

    Accounts.set_preference(
      socket.assigns.current_user,
      "current_team_id",
      team.id
    )

    {:noreply,
     socket
     |> assign(current_team: team)
     |> get_tasks()
     |> get_changes()
     |> get_project_progress()}
  end

  def handle_event("done_tasks_from_older_weeks_requested", _params, socket) do
    done_months_ago = case socket.assigns.done_months_ago do
      nil -> -1
      num when num >= 0 -> -1
      num -> num - 1
    end

    socket = assign(socket, loading_done_tasks: true)
    send(self(), {:load_done_tasks, done_months_ago})
    {:noreply, socket}
  end

  def handle_event("done_tasks_from_recent_weeks_requested", _params, socket) do
    done_months_ago = case socket.assigns.done_months_ago do
      num when num >= -1 -> nil
      num -> num + 1
    end

    socket = assign(socket, loading_done_tasks: true)
    send(self(), {:load_done_tasks, done_months_ago})
    {:noreply, socket}
  end

  def handle_event("changes_for_previous_week_requested", _params, socket) do
    changes_week_number = socket.assigns.changes_week_number - 1

    {:noreply,
     socket
     |> assign(changes_week_number: changes_week_number)
     |> get_changes()}
  end

  def handle_event("changes_for_next_week_requested", _params, socket) do
    changes_week_number =
      if socket.assigns.changes_week_number < 0,
        do: socket.assigns.changes_week_number + 1,
        else: 0

    {:noreply,
     socket
     |> assign(changes_week_number: changes_week_number)
     |> get_changes()}
  end

  def handle_event("unset_current_team", _params, socket) do
    Accounts.set_preference(
      socket.assigns.current_user,
      "current_team_id",
      nil
    )

    {:noreply,
     socket
     |> assign(current_team: nil)
     |> assign_new_task_ids()
     |> get_tasks()
     |> get_changes()
     |> get_project_progress()}
  end

  def handle_event("show_hide_team_members", params, socket) do
    show_hide_team_members(socket, params["team_slug"])
  end

  def handle_event("set_current_team", params, socket) do
    set_current_team(socket, params["team_slug"])
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

  def handle_event("hide_changelog", _params, socket) do
    set_changelog_visibility(socket, false)
  end

  def handle_event("show_changelog", _params, socket) do
    set_changelog_visibility(socket, true)
  end

  def handle_event("tag_clicked", params, socket) do
    case params["tag-type"] do
      "team" ->
        set_current_team(socket, params["tag-slug"])

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
    current_user = socket.assigns.current_user

    case params["action"] do
      "start_task" -> Tasks.start_task(task, current_user)
      "finish_task" -> Tasks.finish_task(task, current_user)
      "deliver_task" -> Tasks.deliver_task(task, current_user)
      "accept_task" -> Tasks.accept_task(task, current_user)
      "reject_task" -> Tasks.reject_task(task, current_user)
      "estimate_task" -> Tasks.estimate_task(task, params["estimate"], current_user)
    end

    {:noreply,
     socket
     |> get_tasks()
     |> get_changes()
     |> get_project_progress()}
  end

  def handle_event("move_tasks_to_team", params, socket) do
    task_slugs = String.split(params["selected_tasks"], ",")
    team_slug = params["team_slug"]
    team = Teams.get_team_by_slug!(team_slug)

    Enum.each(task_slugs, fn task_slug ->
      task = Tasks.get_task_by_slug!(task_slug)

      Tasks.update_task(task, %{current_user_id: socket.assigns.current_user.id, team_id: team.id})
    end)

    {:noreply,
     socket
     |> get_tasks()
     |> get_changes()
     |> assign_new_team_id()
     |> get_project_progress()}
  end

  def handle_event("add_tasks_to_project", params, socket) do
    task_slugs = String.split(params["selected_tasks"], ",")
    project_slug = params["project_slug"]
    project = Projects.get_project_by_slug!(project_slug)

    Enum.each(task_slugs, fn task_slug ->
      task = Tasks.get_task_by_slug!(task_slug)

      unless Enum.member?(task.project_tags, project.tag) do
        Tasks.update_task(task, %{
          current_user_id: socket.assigns.current_user.id,
          project_tags: [project.tag | task.project_tags]
        })
      end
    end)

    {:noreply,
     socket
     |> get_tasks()
     |> get_changes()
     # This should also reset the add to project button.
     |> assign_new_project_id()
     |> get_project_progress()}
  end

  def handle_event("task_actions", params, socket) do
    current_user = socket.assigns.current_user
    task_slugs = params["task_slugs"]
    action = params["action"]

    case action do
      "delete_tasks" -> Tasks.delete_tasks_with_slugs(current_user, task_slugs)
      "move_to_later" -> Tasks.move_tasks_with_slugs_to_stage(current_user, task_slugs, "Later")
      "move_to_now" -> Tasks.move_tasks_with_slugs_to_stage(current_user, task_slugs, "Now")
      _ -> nil
    end

    {:noreply,
     socket
     |> assign_new_project_id()
     |> get_tasks()
     |> get_changes()}
  end

  def handle_event("remove_tasks_from_project", params, socket) do
    project = Projects.get_project_by_slug!(params["project_slug"])
    task_slugs = params["task_slugs"]

    Enum.each(task_slugs, fn task_slug ->
      task = Tasks.get_task_by_slug!(task_slug)

      Tasks.update_task(task, %{
        current_user_id: socket.assigns.current_user.id,
        project_tags: List.delete(task.project_tags, project.tag)
      })
    end)

    {:noreply,
     socket
     |> get_tasks()
     |> get_changes()
     |> assign_new_project_id()
     |> get_project_progress()}
  end

  def handle_event(
        "move_task",
        %{
          "action" => action,
          "active_task_slug" => active_task_slug,
          "affected_task_slug" => affected_task_slug,
          "target_project_slug" => project_slug
        } = _params,
        socket
      ) do
    task = Tasks.get_task_by_slug!(active_task_slug)
    affected_task = Tasks.get_task_by_slug!(affected_task_slug)
    project = if is_nil(project_slug), do: nil, else: Projects.get_project_by_slug!(project_slug)

    if is_nil(project) or
         (Enum.member?(task.project_tags, project.tag) and
            Enum.member?(affected_task.project_tags, project.tag)) do
      case action do
        "move_above" -> Tasks.move_task_above(task, affected_task, socket.assigns.current_user)
        "move_below" -> Tasks.move_task_below(task, affected_task, socket.assigns.current_user)
      end
    end

    {:noreply,
     socket
     |> get_tasks()
     |> get_changes()
     |> assign_new_task_ids()
     |> get_project_progress()}
  end

  def handle_event(
        "move_task",
        %{
          "action" => "cancel"
        } = _params,
        socket
      ) do
    {:noreply,
     socket
     |> get_tasks()
     |> get_project_progress()}
  end

  def set_changelog_visibility(socket, value) do
    Accounts.set_preference(
      socket.assigns.current_user,
      "show_changelog",
      value
    )

    {:noreply,
     socket
     |> assign(show_changelog: value)}
  end
end
