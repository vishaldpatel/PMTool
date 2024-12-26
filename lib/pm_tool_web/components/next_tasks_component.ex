defmodule PmToolWeb.NextTasksComponent do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks
  alias PmTool.Tasks.Task

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Next</span>

      <form id="next_task_options" style="display: none;" phx-submit="delete_tasks">
        <button class="font-bold rounded">
          <svg
            class="h-6 w-6 text-red-500"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" /> <line x1="4" y1="7" x2="20" y2="7" />
            <line x1="10" y1="11" x2="10" y2="17" /> <line x1="14" y1="11" x2="14" y2="17" />
            <path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" />
            <path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" />
          </svg>
        </button>
      </form>
      <%= if @tasks do %>
        <%= for {index, current_tasks} <- @tasks do %>
          <%= if index == 1 do %>
            <div class="font-bold text-gray-400 uppercase text-xs mb-1 mt-[-18px] text-right">Next Iteration</div>
          <% else %>
            <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">{index} Iterations</div>
          <% end %>
          <ul phx-hook="Sortable" id={@id}>
            <%= for task <- current_tasks do %>
              <.live_component
                module={PmToolWeb.TaskComponents}
                id={"task-#{task.slug}#{@timestamp}"}
                no_move={false}
                task={task}
              />
            <% end %>
          </ul>
        <% end %>
      <% end %>
      <.live_component
        module={PmToolWeb.TaskComponents}
        id={@new_task_id}
        current_user={@current_user}
        task={%Task{stage: "Now", estimate: 1, status: "Unappraised"}}
      />
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
