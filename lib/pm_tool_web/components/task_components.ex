defmodule PmToolWeb.TaskComponents do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks
  alias PmTool.Tasks.Task

  @status_colors %{"Unstarted" => "bg-gray-600 hover:bg-gray-500", "Started" => "bg-yellow-700 hover:bg-yellow-600", "Finished" => "bg-lime-700 hover:bg-lime-600", "Delivered" => "bg-emerald-800 hover:bg-emerald-700", "Rejected" => "bg-red-900 hover:bg-red-800", "Accepted" => "bg-sky-700 hover:bg-sky-600"}

  defp status_colors(status) do 
    @status_colors[status]
  end

  def render(assigns) do
    if assigns.task.id do
      show_task(assigns)
    else
      new_task(assigns)
    end
  end

  def mount(socket) do
    {:ok, assign(socket,
      task: if Map.has_key?(socket.assigns, :task) do socket.assigns.task else %Task{} end,
      no_move: false,
      actions: true
    )}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, assign(socket, 
      show_task: "flex", 
      show_task_edit: "hidden")}
  end

  def handle_event("update_task", %{"task" => task_params}, socket) do
    if task_params["slug"] == socket.assigns.task.slug do
      timestamp = DateTime.to_unix(DateTime.utc_now())
      case Tasks.update_task(socket.assigns.task, task_params) do
        {:ok, %Task{} = updated_task} ->
          send(self(), {:task_updated, updated_task})
          {:noreply, assign(socket, 
            task: updated_task, 
            id: "task-#{updated_task.slug}#{timestamp}",
            show_task: "flex", 
            show_task_edit: "hidden")}
        {:error, _changeset} ->
          {:noreply, assign(socket, 
            show_task: "hidden", 
            show_task_edit: "flex")}
      end
    end
  end

  def handle_event("create_task", %{"task" => task_params}, socket) do
    task_params = 
      %{"creator_id" => socket.assigns.current_user.id, "owner_id" => socket.assigns.current_user.id}
      |> Enum.into(task_params)
    case Tasks.create_task(task_params) do
      {:ok, _task} ->
        send(self(), {:new_task_created})
        {:noreply, assign(socket, 
          show_task: "flex", 
          show_task_edit: "hidden")}
      {:error, _changeset} ->
        {:noreply, assign(socket, 
          show_task: "hidden", 
          show_task_edit: "flex")}
    end
  end
  
  defp show_task(assigns) do
    ~H"""
    <li
      class="text-left flex-auto">
      <div
        draggable={if @no_move == true do "false" else "true" end}
        phx-click={
          JS.toggle_class("flex", to: "#show-#{@id}")
          |> JS.toggle_class("hidden", to: "#show-#{@id}")
          |> JS.toggle_class("hidden", to: "#edit-#{@id}")
          |> JS.toggle_class("flex", to: "#edit-#{@id}")
        }
        id={"show-#{@id}"}
        class={"draggable_task_item w-full pl-1 pr-1 cursor-pointer border text-right text-md rounded bold #{status_colors(@task.status)} text-gray-100 inline-block flex #{@show_task}"}>
        <div class="inline-block just_title text-left flex flex-auto"><%= @task.name %></div>
        <div class="inline-block inline-block flex-none" onclick="event.stopPropagation()">
          <%= if @actions == true do %>
            <%= if @task.status == "Delivered" do %>
              <button 
                phx-click="task_action"
                phx-value-action="accept_task"
                phx-value-task_slug={@task.slug}
                class="bg-sky-600 hover:bg-sky-500 text-white text-xs px-1 my-1 rounded"
              >Accept</button>
              <button 
                phx-click="task_action"
                phx-value-action="reject_task"
                phx-value-task_slug={@task.slug}
                class="bg-red-600 hover:bg-red-500 text-white text-xs px-1 my-1 rounded"
              >Reject</button>
            <% end %>
            <%= if @task.status == "Finished" do %>
              <button 
                phx-click="task_action"
                phx-value-action="deliver_task"
                phx-value-task_slug={@task.slug}
                class="bg-emerald-800 hover:bg-emerald-600 text-white text-xs px-1 my-1 rounded"
              >Deliver</button>
            <% end %>
            <%= if @task.status == "Started" do %>
              <button 
                phx-click="task_action"
                phx-value-action="finish_task"
                phx-value-task_slug={@task.slug}
                class="bg-lime-700 hover:bg-lime-500 text-white text-xs px-1 my-1 rounded"
              >Finish</button>
            <% end %>
            <%= if @task.status == "Unstarted" or @task.status == "Rejected" do %>
              <button 
                phx-click="task_action" 
                phx-value-action="start_task"
                phx-value-task_slug={@task.slug}
                class="bg-yellow-700 hover:bg-yellow-500 text-white text-xs px-1 my-1 rounded"
              >Start</button>
            <% end %>
          <% end %>
          <input type="hidden" class="task_slug" value={@task.slug}/>
          <input 
            type="checkbox" 
            name={"#{@task.stage}_task_slugs[]"} 
            class="rounded" 
            style="margin-bottom: 1px;"
            phx-click={
              JS.dispatch("task_checkbox_clicked", detail: %{id: @id, slug: @task.slug, stage: @task.stage})
            } />
        </div>
      </div>
      <.task_form task={@task} id={@id} action="update_task" myself={@myself} show_task_edit={@show_task_edit} />
    </li>
    """
  end

  defp new_task(assigns) do
    ~H"""
    <div>
      <.task_form task={@task} id={@id} action="create_task" myself={@myself} show_task_edit={@show_task_edit} />
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
    <div id={"edit-"<>@id} class={"text-left #{@show_task_edit}"}>
      <div class="inline-block w-full bg-gray-200 text-left border border-white p-1 rounded">
        <form phx-submit={@action} phx-target={@myself}> 
          <input placeholder="Task Name" name="task[name]" type="text" value={@task.name} class="rounded-sm w-full py-0 px-1 mb-1"/><br/>
          <textarea placeholder="Task Description" name="task[description]" type="text" class="rounded-sm w-full py-0 px-1 mb-1"><%= @task.description %></textarea><br/>
          <select name="task[estimate]" class="w-full py-0 px-2 mb-1 rounded-sm" value={@task.estimate}>
            <%= for estimate <- Tasks.Task.estimates() do %>
              <option value={estimate} selected={@task.estimate == estimate}><%= estimate %></option>
            <% end %>
          </select><br />
          <select name="task[status]" class="w-full py-0 px-2 mb-1 rounded-sm" value={@task.status}>
            <%= for status <- Tasks.Task.statuses() do %>
              <option value={status} selected={@task.status == status}><%= status %></option>
            <% end %>
          </select><br />
          <select name="task[stage]" class="w-full py-0 px-2 mb-1 rounded-sm" value={@task.stage}>
            <%= for stage <- Tasks.Task.stages() do %>
              <option value={stage} selected={@task.stage == stage}><%= stage %></option>
            <% end %>
          </select><br />
          <input type="hidden" name="task[slug]" value={@task.slug} />
          <div class="w-full text-right">
            <button type="reset"
              phx-click={
                JS.toggle_class("flex", to: "#edit-#{@id}")
                |> JS.toggle_class("hidden", to: "#edit-#{@id}")
                |> JS.toggle_class("hidden", to: "#show-"<>@id)
                |> JS.toggle_class("flex", to: "#show-#{@id}")
              }>Cancel</button>
            <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold px-2 py-1 ml-1 rounded"><%= @save_button_name %></button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
