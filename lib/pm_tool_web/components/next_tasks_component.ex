defmodule PmToolWeb.NextTasksComponent do
  use PmToolWeb, :live_component

  alias PmTool.Tasks

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <span class="font-semibold uppercase align-top ml-1 text-gray-400 droppable_task_list">
        Next
      </span>

      <%= if @tasks do %>
        <%= for {index, current_tasks} <- @tasks do %>
          <%= if index == 1 do %>
            <div class="font-bold text-gray-400 uppercase text-xs mb-1 mt-[-12px] text-right">
              Next Week
            </div>
          <% else %>
            <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">
              {index} Weeks
            </div>
          <% end %>
          <ul phx-hook="Sortable" id={"#{@id}-group-#{index}"}>
            <%= for task <- current_tasks do %>
              <.live_component
                module={PmToolWeb.TaskComponent}
                id={"task-#{task.slug}#{@timestamp}"}
                draggable={true}
                task={task}
                show_task={if @open_tasks[task.slug], do: "hidden", else: "flex"}
                show_task_edit={if @open_tasks[task.slug], do: "flex", else: "hidden"}
              />
            <% end %>
          </ul>
        <% end %>
      <% end %>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> maybe_get_current_task()

    {:ok, socket}
  end

  defp maybe_get_current_task(socket) do
    case socket.assigns["slug"] do
      nil ->
        assign(socket, task: nil)

      slug ->
        task = Tasks.get_task_by_slug!(slug)
        assign(socket, task: task)
    end
  end
end
