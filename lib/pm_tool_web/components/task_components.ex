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
      %{"creator_id" => socket.assigns.current_user.id, "owner_id" => socket.assigns.current_user.id} |> 
      Enum.into task_params
    case new_task = Tasks.create_task(task_params) do
      {:ok, _task} ->
        pid = self()
        new_task_id = "new-task-#{DateTime.to_unix(DateTime.utc_now())}"
        send(pid, {:new_task_created, new_task_id})
        {:noreply, assign(socket, 
          id: new_task_id,
          show_task: "", 
          show_taskV_edit: "display: none;")}
      {:error, changeset} ->
        {:noreply, assign(socket, 
          show_task: "display: none;", 
          show_task_edit: "")}
    end
  end

  defp show_task(assigns) do
    ~H"""
    <div>
      <div id={"show-"<>@id}
          style={@show_task}
          class="pl-2 bg-yellow-100 border">
        <input type="checkbox" name={"check-#{@id}"} phx-click={
          JS.dispatch("task_checkbox_clicked", detail: %{slug: @task.slug})
        }/>
        <div
          class="inline-block"
          phx-click={
            JS.toggle(to: "#show-"<>@id)
            |> JS.toggle(to: "#edit-#{@id}")
          }>
          <span class="just_title"><%= @task.name %></span>
        </div>
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

    ~H"""
    <div id={"edit-"<>@id} style={@show_task_edit} class="bg-gray-100 border border-gray-400">
      <form phx-submit={@action} phx-target={@myself}>
        <input name="task[name]" type="text" value={@task.name} /><br/>
        <textarea name="task[description]" type="text"><%= @task.description %></textarea><br/>
        <select name="task[status]" value={@task.status}>
          <%= for status <- Tasks.Task.statuses() do %>
            <option value={status} selected={@task.status == status}><%= status %></option>
          <% end %>
        </select><br />
        <button><%= save_button_name %></button>
        <input type="hidden" name="task[slug]" value={@task.slug} />
      </form>
      <button 
        phx-click={
          JS.toggle(to: "#show-"<>@id)
          |> JS.toggle(to: "#edit-#{@id}")
        }>Cancel</button>
    </div>
    """
  end
end
