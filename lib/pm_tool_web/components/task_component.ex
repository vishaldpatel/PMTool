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

  defp bg_colors(%Task{status: status} = task) do
    if task.is_milestone != true do
      @status_colors[status]
    else
      "bg-sky-900 hover:bg-sky-700 border-sky-700 pb-[2px]"
    end
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

      task_params =
        %{"current_user_id" => socket.assigns.current_user.id} |> Enum.into(task_params)

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
            "current_user_id" => socket.assigns.current_user.id,
            "creator_id" => socket.assigns.current_user.id
          }

        %Team{} = team ->
          %{
            "current_user_id" => socket.assigns.current_user.id,
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
        class={"inline-block draggable_task_item cursor-pointer border border-gray-600 text-right rounded bold flex #{bg_colors(@task)}"}
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
            <%= if @task.is_milestone == true do %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                class="inline m-auto w-4 h-4 text-orange-500"
              >
                <path
                  fill-rule="evenodd"
                  d="M9.315 7.584C12.195 3.883 16.695 1.5 21.75 1.5a.75.75 0 0 1 .75.75c0 5.056-2.383 9.555-6.084 12.436A6.75 6.75 0 0 1 9.75 22.5a.75.75 0 0 1-.75-.75v-4.131A15.838 15.838 0 0 1 6.382 15H2.25a.75.75 0 0 1-.75-.75 6.75 6.75 0 0 1 7.815-6.666ZM15 6.75a2.25 2.25 0 1 0 0 4.5 2.25 2.25 0 0 0 0-4.5Z"
                  clip-rule="evenodd"
                />
                <path d="M5.26 17.242a.75.75 0 1 0-.897-1.203 5.243 5.243 0 0 0-2.05 5.022.75.75 0 0 0 .625.627 5.243 5.243 0 0 0 5.022-2.051.75.75 0 1 0-1.202-.897 3.744 3.744 0 0 1-3.008 1.51c0-1.23.592-2.323 1.51-3.008Z" />
              </svg>
            <% else %>
              <%= if Ecto.assoc_loaded?(@task.owner) and @task.owner do %>
                <img
                  alt={@task.owner.name}
                  title={@task.owner.name}
                  class="w-4 h-4 rounded-full inline m-auto border-[1px] border-gray-200"
                  src={"/images/team_members/#{@task.owner.email}.png"}
                />
              <% end %>
            <% end %>
            <span class="inline m-auto">{@task.name}</span>
            <%= if not is_nil(@due_days) do %>
              <%= cond do %>
                <% @due_days == 0 -> %>
                  <span
                    title={"Due today: #{@task.due_date}"}
                    class="inline-block text-xs text-black m-auto px-1 bg-yellow-500 rounded border-[1px] border-gray-100"
                  >
                    Today
                  </span>
                <% @due_days < 0 -> %>
                  <%= if @task.is_milestone == true do %>
                    <span
                      title={@task.due_date}
                      class="inline-block text-xs text-black m-auto px-1 bg-yellow-500 rounded border-[1px] border-gray-100"
                    >
                      {@task.due_date}
                    </span>
                  <% else %>
                    <span
                      title={"It was due on #{@task.due_date}"}
                      class="inline-block text-xs text-white m-auto px-1 bg-red-600 rounded border-[1px] border-yellow-500"
                    >
                      Late
                    </span>
                  <% end %>
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
          <input type="hidden" class="task_slug" value={@task.slug} />
          <div class="inline-block flex-none m-auto relative">
            <%= if @task.is_milestone == true do %>
              <%= if is_nil(@task.due_date) do %>
                <%= if @task.status != "Accepted" do %>
                  <button
                    phx-click="task_action"
                    phx-value-action="accept_task"
                    phx-value-task_slug={@task.slug}
                    class="bg-sky-600 hover:bg-sky-500 text-white text-xs px-1 my-1 rounded"
                  >
                    Reached
                  </button>
                <% else %>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="w-4 h-4 text-orange-500 inline m-auto"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M9 4.5a.75.75 0 0 1 .721.544l.813 2.846a3.75 3.75 0 0 0 2.576 2.576l2.846.813a.75.75 0 0 1 0 1.442l-2.846.813a3.75 3.75 0 0 0-2.576 2.576l-.813 2.846a.75.75 0 0 1-1.442 0l-.813-2.846a3.75 3.75 0 0 0-2.576-2.576l-2.846-.813a.75.75 0 0 1 0-1.442l2.846-.813A3.75 3.75 0 0 0 7.466 7.89l.813-2.846A.75.75 0 0 1 9 4.5ZM18 1.5a.75.75 0 0 1 .728.568l.258 1.036c.236.94.97 1.674 1.91 1.91l1.036.258a.75.75 0 0 1 0 1.456l-1.036.258c-.94.236-1.674.97-1.91 1.91l-.258 1.036a.75.75 0 0 1-1.456 0l-.258-1.036a2.625 2.625 0 0 0-1.91-1.91l-1.036-.258a.75.75 0 0 1 0-1.456l1.036-.258a2.625 2.625 0 0 0 1.91-1.91l.258-1.036A.75.75 0 0 1 18 1.5ZM16.5 15a.75.75 0 0 1 .712.513l.394 1.183c.15.447.5.799.948.948l1.183.395a.75.75 0 0 1 0 1.422l-1.183.395c-.447.15-.799.5-.948.948l-.395 1.183a.75.75 0 0 1-1.422 0l-.395-1.183a1.5 1.5 0 0 0-.948-.948l-1.183-.395a.75.75 0 0 1 0-1.422l1.183-.395c.447-.15.799-.5.948-.948l.395-1.183A.75.75 0 0 1 16.5 15Z"
                      clip-rule="evenodd"
                    />
                  </svg>
                <% end %>
              <% end %>
            <% else %>
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
            <% end %>
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
            class="text-sm rounded-sm w-full py-0 px-1 mb-1"
          /><br />
          <input
            id={"edit-#{@id}-is_milestone"}
            type="hidden"
            name="task[is_milestone]"
            value={if @task.is_milestone == true, do: "true", else: "false"}
          />
          <input
            class="py-0 rounded-sm"
            type="checkbox"
            phx-click={
              JS.toggle_attribute({"value", "true", "false"}, to: "#edit-#{@id}-is_milestone")
            }
            checked={@task.is_milestone == true}
          />
          <label for="milestone" class="text-sm">Milestone</label>
          <label for="due_date" class="text-sm ml-2">Due Date</label>
          <input
            class="py-0 mb-1 text-sm uppercase px-1"
            type="date"
            name="task[due_date]"
            value={@task.due_date}
          /><br />
          <textarea
            placeholder="Task Description"
            name="task[description]"
            type="text"
            class="text-sm rounded-sm w-full py-0 px-1 mb-1 h-[150px]"
          ><%= @task.description %></textarea><br />
          <%= if Ecto.assoc_loaded?(@task.team) and @task.team do %>
            <select
              name="task[owner_id]"
              class="text-sm w-1/2 py-0 px-2 mb-1 rounded-sm"
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
              class="text-sm w-1/5 py-0 px-2 mb-1 rounded-sm"
              value={@task.estimate}
            >
              <%= for estimate <- Tasks.Task.estimates() do %>
                <option value={estimate} selected={@task.estimate == estimate}>{estimate}</option>
              <% end %>
            </select>
            hours <br />
            <select
              name="task[status]"
              class="text-sm w-3/5 py-0 px-2 mb-1 rounded-sm"
              value={@task.status}
            >
              <%= for status <- Tasks.Task.statuses() do %>
                <option value={status} selected={@task.status == status}>{status}</option>
              <% end %>
            </select>
            <select
              name="task[stage]"
              class="text-sm w-1/3 py-0 px-2 mb-1 rounded-sm"
              value={@task.stage}
            >
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
                |> JS.toggle_class("hidden", to: "#new_task_helper")
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
