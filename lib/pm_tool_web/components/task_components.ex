defmodule PmToolWeb.TaskComponents do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks
  alias PmTool.Tasks.Task

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
      no_check: false,
      no_move: false
    )}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, assign(socket, 
      show_task: "", 
      show_task_edit: "display: none;")}
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
            show_task: "", 
            show_task_edit: "display: none;")}
        {:error, _changeset} ->
          {:noreply, assign(socket, 
            show_task: "display: none;", 
            show_task_edit: "")}
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
          show_task: "", 
          show_task_edit: "display: none;")}
      {:error, _changeset} ->
        {:noreply, assign(socket, 
          show_task: "display: none;", 
          show_task_edit: "")}
    end
  end
  
  defp show_task(assigns) do
    ~H"""
    <li
      class="text-left">
      <div
        style={@show_task}
        draggable={if @no_move == true do "false" else "true" end}
        phx-click={
          JS.toggle(to: "#show-#{@id}")
          |> JS.toggle(to: "#edit-#{@id}")
        }
        id={"show-#{@id}"}
        class="draggable_task_item align-top w-full pl-1 pr-1 cursor-pointer border text-left text-md rounded bold bg-gray-600 text-gray-100 inline-block">
        <span class="just_title text-left w-11/12"><%= @task.name %></span>
        <input type="hidden" class="task_slug" value={@task.slug}/>
        <%= if @no_check == false do %>
          <input 
            type="checkbox" 
            name={"#{@task.stage}_task_slugs[]"} 
            class="float-right align-top mt-1 rounded" 
            phx-click={
              JS.dispatch("task_checkbox_clicked", detail: %{id: @id, slug: @task.slug})
            }/>
        <% end %>
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
    <div id={"edit-"<>@id} style={@show_task_edit} class="text-left">
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
                JS.toggle(to: "#show-"<>@id)
                |> JS.toggle(to: "#edit-#{@id}")
              }>Cancel</button>
            <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold px-2 py-1 ml-1 rounded"><%= @save_button_name %></button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
