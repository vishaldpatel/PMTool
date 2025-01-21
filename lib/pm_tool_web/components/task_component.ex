defmodule PmToolWeb.TaskComponent do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks
  alias PmTool.Tasks.Task
  alias PmTool.Projects.Project
  alias PmTool.Teams.Team

  @status_colors %{
    "Unappraised" => "bg-gray-600 hover:bg-gray-500",
    "Unstarted" => "bg-gray-600 hover:bg-gray-500",
    "Started" => "bg-yellow-700 hover:bg-yellow-600",
    "Finished" => "bg-lime-700 hover:bg-lime-600",
    "Delivered" => "bg-emerald-800 hover:bg-emerald-700",
    "Rejected" => "bg-red-900 hover:bg-red-800",
    "Accepted" => "bg-sky-700 hover:bg-sky-600",
    "Closed" => "bg-gray-900 hover:bg-gray-800"
  }

  defp status_colors(status) do
    @status_colors[status]
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       task: %Task{stage: "Now", estimate: 1, status: "Unappraised"},
       project: %Project{slug: nil},
       draggable: true,
       actions: true,
       show_task: "flex",
       show_task_edit: "hidden",
       hide_project_tag: false,
       current_team: nil
     )}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      if socket.assigns.task.due_date do
        assign(socket, due_days: Date.diff(socket.assigns.task.due_date, Date.utc_today()))
      else
        assign(socket, due_days: nil)
      end

    socket =
      if is_nil(socket.assigns.task.id) and socket.assigns.current_team do
        assign(socket,
          task:
            socket.assigns.task
            |> Map.put(:team_id, socket.assigns.current_team.id)
            |> Map.put(:team, socket.assigns.current_team)
        )
      else
        socket
      end

    {:ok, socket}
  end

  def render(assigns) do
    if assigns.task.id do
      show_task(assigns)
    else
      new_task(assigns)
    end
  end

  def handle_event("update_task", %{"task" => task_params}, socket) do
    if task_params["slug"] == socket.assigns.task.slug do
      timestamp = DateTime.to_unix(DateTime.utc_now())

      case Tasks.update_task(socket.assigns.task, task_params) do
        {:ok, %Task{} = updated_task} ->
          send(self(), {:task_updated, updated_task})

          {:noreply,
           assign(socket,
             task: updated_task,
             id: "task-#{updated_task.slug}#{timestamp}",
             show_task: "flex",
             show_task_edit: "hidden"
           )}

        {:error, _changeset} ->
          {:noreply,
           assign(socket,
             show_task: "hidden",
             show_task_edit: "flex"
           )}
      end
    end
  end

  def handle_event("create_task", %{"task" => task_params}, socket) do
    task_params =
      case socket.assigns.current_team do
        nil ->
          %{
            "creator_id" => socket.assigns.current_user.id
          }

        %Team{} = team ->
          %{
            "creator_id" => socket.assigns.current_user.id,
            "team_id" => team.id
          }
      end
      |> Enum.into(task_params)

    case Tasks.create_task(task_params) do
      {:ok, _task} ->
        send(self(), {:new_task_created})

        {:noreply,
         assign(socket,
           show_task: "flex",
           show_task_edit: "hidden"
         )}

      {:error, _changeset} ->
        {:noreply,
         assign(socket,
           show_task: "hidden",
           show_task_edit: "flex"
         )}
    end
  end

  defp show_task(assigns) do
    ~H"""
    <li class="task_list_item text-left mt-0.5">
      <div
        draggable={if @draggable, do: "true", else: "false"}
        class={"inline-block draggable_task_item cursor-pointer border border-gray-500 text-right rounded bold flex #{status_colors(@task.status)}"}
      >
        <div
          id={"show-#{@id}"}
          phx-click={
            JS.toggle_class("flex", to: "#show-#{@id}")
            |> JS.toggle_class("hidden", to: "#show-#{@id}")
            |> JS.toggle_class("hidden", to: "#edit-#{@id}")
            |> JS.toggle_class("flex", to: "#edit-#{@id}")
          }
          class={"inline-block text-md w-full pl-1 pr-1 text-gray-100 #{@show_task}"}
        >
          <div class="inline-block just_title text-left flex-auto">
            <%= if Ecto.assoc_loaded?(@task.owner) and @task.owner do %>
              <img
                alt={@task.owner.name}
                title={@task.owner.name}
                class="w-4 h-4 rounded-full inline align-middle mb-[2px] mr-[-2px]"
                src={"/images/team_members/#{@task.owner.email}.png"}
              />
            <% end %>
            {@task.name}
            <%= if @due_days do %>
              <%= cond do %>
                <% @due_days == 0 -> %>
                  <span
                    title={"Due today: #{@task.due_date}"}
                    class="inline-block text-xs text-black m-auto px-1 bg-yellow-500 rounded border-[1px] border-gray-100"
                  >
                    Today
                  </span>
                <% @due_days < 0 -> %>
                  <span
                    title={"It was due on #{@task.due_date}"}
                    class="inline-block text-xs text-white m-auto px-1 bg-red-600 rounded border-[1px] border-yellow-500"
                  >
                    Late
                  </span>
                <% @due_days > 0 -> %>
                  <span
                    title={"Due in #{@due_days} days on #{@task.due_date}"}
                    class="inline-block text-xs text-gray-200 m-auto px-1 rounded bg-sky-700 border-[1px] border-white"
                  >
                    {@due_days}
                  </span>
                <% true -> %>
              <% end %>
            <% end %>
            <%= if Ecto.assoc_loaded?(@task.team) and @task.team do %>
              <.live_component
                id={"show-team-tags-#{@id}"}
                module={PmToolWeb.TagComponent}
                color="text-orange-100 bg-orange-800 hover:bg-orange-600"
                tag={@task.team.name}
                tag_type="team"
                tag_slug={@task.team.slug}
                tooltip={"Show #{@task.team.name} Tasks Only"}
              />
            <% end %>
            <.live_component
              id={"show-project-tags-#{@id}"}
              module={PmToolWeb.TagsComponent}
              tags={
                if @hide_project_tag == true,
                  do: @task.project_tags -- [@project.tag],
                  else: @task.project_tags
              }
              color="text-gray-200 bg-gray-700 hover:bg-gray-600"
              tag_type="project"
            />
            <.live_component
              id={"show-tags-#{@id}"}
              module={PmToolWeb.TagsComponent}
              tags={@task.tags}
            />
          </div>
          <div class="inline-block flex-none m-auto relative">
            <%= if @actions == true do %>
              <%= if @task.status == "Delivered" do %>
                <button
                  phx-click="task_action"
                  phx-value-action="accept_task"
                  phx-value-task_slug={@task.slug}
                  class="bg-sky-600 hover:bg-sky-500 text-white text-xs px-1 my-1 rounded"
                >
                  Accept
                </button>
                <button
                  phx-click="task_action"
                  phx-value-action="reject_task"
                  phx-value-task_slug={@task.slug}
                  class="bg-red-600 hover:bg-red-500 text-white text-xs px-1 my-1 rounded"
                >
                  Reject
                </button>
              <% end %>
              <%= if @task.status == "Finished" do %>
                <button
                  phx-click="task_action"
                  phx-value-action="deliver_task"
                  phx-value-task_slug={@task.slug}
                  class="bg-emerald-800 hover:bg-emerald-600 text-white text-xs px-1 my-1 rounded"
                >
                  Deliver
                </button>
              <% end %>
              <%= if @task.status == "Started" do %>
                <button
                  phx-click="task_action"
                  phx-value-action="finish_task"
                  phx-value-task_slug={@task.slug}
                  class="bg-lime-700 hover:bg-lime-500 text-white text-xs px-1 my-1 rounded"
                >
                  Finish
                </button>
              <% end %>
              <%= if @task.status == "Unstarted" or @task.status == "Rejected" do %>
                <button
                  phx-click="task_action"
                  phx-value-action="start_task"
                  phx-value-task_slug={@task.slug}
                  class="bg-yellow-700 hover:bg-yellow-500 text-white text-xs px-1 my-1 rounded"
                >
                  Start
                </button>
              <% end %>
              <%= if @task.status == "Unappraised" do %>
                <span class="estimate_number text-bold inline-block absolute text-orange-200 top-0 left-0 text-xs">
                </span>
                <svg
                  width="29"
                  height="20"
                  class="estimation_station inline-block rounded-bl-sm rounded-tr-sm mb-[2px]"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <rect
                    y="15"
                    x="0"
                    width="4"
                    height="5"
                    value="1"
                    phx-click="task_action"
                    phx-value-action="estimate_task"
                    phx-value-task_slug={@task.slug}
                    phx-value-estimate="1"
                    class="estimator fill-yellow-300 hover:fill-yellow-500"
                  />
                  <rect
                    y="13"
                    x="5"
                    width="4"
                    height="7"
                    value="2"
                    phx-click="task_action"
                    phx-value-action="estimate_task"
                    phx-value-task_slug={@task.slug}
                    phx-value-estimate="2"
                    class="estimator fill-yellow-300 hover:fill-yellow-500"
                  />
                  <rect
                    y="10"
                    x="10"
                    width="4"
                    height="10"
                    value="4"
                    phx-click="task_action"
                    phx-value-action="estimate_task"
                    phx-value-task_slug={@task.slug}
                    phx-value-estimate="4"
                    class="estimator fill-orange-300 hover:fill-orange-500"
                  />
                  <rect
                    y="8"
                    x="15"
                    width="4"
                    height="12"
                    value="6"
                    phx-click="task_action"
                    phx-value-action="estimate_task"
                    phx-value-task_slug={@task.slug}
                    phx-value-estimate="6"
                    class="estimator fill-orange-300 hover:fill-orange-500"
                  />
                  <rect
                    y="5"
                    x="20"
                    width="4"
                    height="15"
                    value="8"
                    phx-click="task_action"
                    phx-value-action="estimate_task"
                    phx-value-task_slug={@task.slug}
                    phx-value-estimate="8"
                    class="estimator fill-orange-300 hover:fill-orange-500"
                  />
                  <rect
                    y="0"
                    x="25"
                    width="4"
                    height="20"
                    value="12"
                    phx-click="task_action"
                    phx-value-action="estimate_task"
                    phx-value-task_slug={@task.slug}
                    phx-value-estimate="12"
                    class="estimator fill-red-500 hover:fill-red-600"
                  />
                </svg>
              <% end %>
            <% end %>
            <input type="hidden" class="task_slug" value={@task.slug} />
            <input
              type="checkbox"
              name={"#{@task.stage}_task_slugs[]"}
              class="rounded"
              style="margin-bottom: 2px;"
              phx-click={
                JS.dispatch("task_checkbox_clicked",
                  detail: %{
                    id: @id,
                    slug: @task.slug,
                    stage: @task.stage,
                    project_slug: @project.slug
                  }
                )
              }
            />
          </div>
        </div>
        <.task_form
          task={@task}
          id={@id}
          action="update_task"
          myself={@myself}
          show_task_edit={@show_task_edit}
        />
      </div>
    </li>
    """
  end

  defp new_task(assigns) do
    ~H"""
    <div>
      <.task_form
        task={@task}
        id={@id}
        action="create_task"
        myself={@myself}
        show_task_edit={@show_task_edit}
      />
    </div>
    """
  end

  defp task_form(assigns) do
    save_button_name =
      if assigns.action == "create_task" do
        "Create"
      else
        "Update"
      end

    assigns = assign(assigns, :save_button_name, save_button_name)

    ~H"""
    <div id={"edit-#{@id}"} class={"text-left w-full #{@show_task_edit}"}>
      <div class="inline-block w-full bg-gray-200 text-left border border-gray-500 p-1 rounded">
        <form phx-submit={@action} phx-target={@myself}>
          <input
            placeholder="Task Name"
            name="task[name]"
            type="text"
            value={@task.name}
            class="rounded-sm w-full py-0 px-1 mb-1"
          /><br />
          <input
            class="py-0 mb-1"
            type="checkbox"
            name="task[is_milestone]"
            checked={@task.is_milestone == true}
            value="true"
          />
          <label for="milestone">Milestone</label>
          <br />
          <label for="due_date">Due Date</label>
          <input class="py-0 mb-1" type="date" name="task[due_date]" value={@task.due_date} /><br />
          <textarea
            placeholder="Task Description"
            name="task[description]"
            type="text"
            class="rounded-sm w-full py-0 px-1 mb-1"
          ><%= @task.description %></textarea><br />
          <%= if Ecto.assoc_loaded?(@task.team) and @task.team do %>
            <select
              name="task[owner_id]"
              class="w-full py-0 px-2 mb-1 rounded-sm"
              value={@task.owner_id}
            >
              <%= for member <- @task.team.team_members do %>
                <option value={member.id} selected={@task.owner_id == member.id}>
                  {member.name}
                </option>
              <% end %>
            </select>
          <% end %>
          <%= if @save_button_name == "Create" do %>
            <input type="hidden" name="task[stage]" value={@task.stage} />
          <% else %>
            <select
              name="task[estimate]"
              class="w-full py-0 px-2 mb-1 rounded-sm"
              value={@task.estimate}
            >
              <%= for estimate <- Tasks.Task.estimates() do %>
                <option value={estimate} selected={@task.estimate == estimate}>{estimate}</option>
              <% end %>
            </select>
            <br />
            <select name="task[status]" class="w-full py-0 px-2 mb-1 rounded-sm" value={@task.status}>
              <%= for status <- Tasks.Task.statuses() do %>
                <option value={status} selected={@task.status == status}>{status}</option>
              <% end %>
            </select>
            <br />
            <select name="task[stage]" class="w-full py-0 px-2 mb-1 rounded-sm" value={@task.stage}>
              <%= for stage <- Tasks.Task.stages() do %>
                <option value={stage} selected={@task.stage == stage}>{stage}</option>
              <% end %>
            </select>
            <br />
          <% end %>
          <input type="hidden" name="task[slug]" value={@task.slug} />
          <.live_component
            id={"edit-tags-#{@id}"}
            module={PmToolWeb.TagsComponent}
            tags={@task.tags}
            type="task"
            edit_tags={true}
          />
          <div class="w-full text-right">
            <a
              href={"/tasks/#{@task.slug}"}
              onclick="event.preventDefault(); navigator.clipboard.writeText(event.target.href)"
              class="float-left my-1 bg-orange-100 hover:bg-orange-200 text-orange-600 text-sm px-2 py-1 rounded"
            >
              Copy Link
            </a>
            <button
              type="reset"
              phx-click={
                JS.toggle_class("flex", to: "#edit-#{@id}")
                |> JS.toggle_class("hidden", to: "#edit-#{@id}")
                |> JS.toggle_class("hidden", to: "#show-" <> @id)
                |> JS.toggle_class("flex", to: "#show-#{@id}")
              }
            >
              Cancel
            </button>
            <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold px-2 py-1 ml-1 rounded">
              {@save_button_name}
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
