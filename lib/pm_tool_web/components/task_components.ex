defmodule PmToolWeb.TaskComponents do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks
  alias PmTool.Tasks.Task

  def render(assigns) do
    # If assigns.task is nil, show new task
    # If assigns.task is not nil, show edit task
    # If assigns has a key named task
    if Map.has_key?(assigns, :task) do
      show_task(assigns)
    else
      new_task(assigns)
    end
  end

  def mount(socket) do
    {:ok, assign(socket, 
      show_task: "", 
      show_task_edit: "display: none;")}
  end

  def handle_event("update_task", %{"task" => task_params}, socket) do
    if task_params["slug"] == socket.assigns.task.slug do
      case Tasks.update_task(socket.assigns.task, task_params) do
        {:ok, %Task{} = updated_task} ->
          {:noreply, assign(socket, 
            task: updated_task, 
            id: "task-"<>updated_task.slug,
            show_task: "", 
            show_taskV_edit: "display: none;")}
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
        pid = self()
        new_task_id = "new-task-#{DateTime.to_unix(DateTime.utc_now())}"
        send(pid, {:new_task_created, new_task_id})
        {:noreply, assign(socket, 
          id: new_task_id,
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
    <div
      class="text-left"
      draggable="true"
      class="Task"
      ondragstart="dragstartHandler(event)"
      >
      <div
        style={@show_task}
        id={"show-#{@id}"}
        class="align-top w-full pl-1 pr-1 cursor-pointer border text-left bg-yellow-100 inline-block"
        phx-click={
          JS.toggle(to: "#show-"<>@id)
          |> JS.toggle(to: "#edit-#{@id}")
        }>
        <span class="just_title text-left"><%= @task.name %></span>
        <input 
          type="checkbox" 
          name="batch_task_slugs[]" 
          class="float-right align-top mt-1 mr-1" 
          phx-click={
            JS.dispatch("task_checkbox_clicked", detail: %{slug: @task.slug})
          }/>
      </div>
      <.task_form task={@task} id={@id} action="update_task" myself={@myself} show_task_edit={@show_task_edit} />
    </div>
    """
  end

  defp new_task(assigns) do
    ~H"""
    <div>
      <.task_form task={%Task{}} id={@id} action="create_task" myself={@myself} show_task_edit={@show_task_edit} />
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
      <div class="inline-block w-full bg-gray-100 border border-gray-400 text-left p-1">
        <form phx-submit={@action} phx-target={@myself}> 
          <input placeholder="Task Name" name="task[name]" type="text" value={@task.name} class="w-full py-0 px-1 mb-1"/><br/>
          <textarea placeholder="Task Description" name="task[description]" type="text" class="w-full py-0 px-1 mb-1"><%= @task.description %></textarea><br/>
          <select name="task[status]" class="w-full py-0 px-2 mb-1" value={@task.status}>
            <%= for status <- Tasks.Task.statuses() do %>
              <option value={status} selected={@task.status == status}><%= status %></option>
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
