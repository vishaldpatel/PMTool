defmodule PmToolWeb.LaterTasksComponent do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks
  alias PmTool.Tasks.Task

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0 droppable_task_list">
      <button
        title="Create New Task To Get Done Later"
        class="font-bold rounded"
        phx-click={JS.toggle_class("hidden", to: "#edit-#{@new_task_id}")}
      >
        <svg
          class="h-6 w-6 text-cyan-500 hover:text-cyan-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Later, Brah 🤙</span>

      <form id="later_task_options" style="display: none;" phx-submit="task_actions">
        <button
          title="Delete Selected Tasks"
          name="action"
          value="delete_tasks"
          class="font-bold rounded"
        >
          <svg
            class="h-6 w-6 text-red-500 hover:text-red-400"
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
        <button
          title="Move Selected Tasks to Now / Next Pile"
          name="action"
          value="move_to_now"
          class="font-bold rounded"
        >
          <svg
            class="h-6 w-6 text-orange-500 hover:text-orange-300"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M17 18a5 5 0 0 0-10 0" /> <line x1="12" y1="2" x2="12" y2="9" />
            <line x1="4.22" y1="10.22" x2="5.64" y2="11.64" /> <line x1="1" y1="18" x2="3" y2="18" />
            <line x1="21" y1="18" x2="23" y2="18" />
            <line x1="18.36" y1="11.64" x2="19.78" y2="10.22" />
            <line x1="23" y1="22" x2="1" y2="22" /> <polyline points="8 6 12 2 16 6" />
          </svg>
        </button>
      </form>
      <%= if @tasks do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for task <- @tasks do %>
            <.live_component
              module={PmToolWeb.TaskComponent}
              id={"task-#{task.slug}#{@timestamp}"}
              task={task}
              draggable={true}
              show_task={if @open_tasks[task.slug], do: "hidden", else: "flex"}
              show_task_edit={if @open_tasks[task.slug], do: "flex", else: "hidden"}
            />
          <% end %>
        </ul>
      <% end %>
      <.live_component
        module={PmToolWeb.TaskComponent}
        id={@new_task_id}
        current_user={@current_user}
        task={%Task{estimate: 1, stage: "Later", status: "Unappraised"}}
        current_team={@current_team}
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
