defmodule PmToolWeb.NowAndNextTasksComponent do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0 droppable_task_list">
      <button
        title="Create New Task"
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

      <button
        title="Split Now and Next Tasks"
        class="font-bold rounded"
        phx-click="separate_now_and_next_tasks"
      >
        <svg
          class="h-6 w-6 text-red-500 hover:text-red-400"
          <svg
          viewBox="0 0 24 24"
          width="24"
          height="24"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
          <rect x="7" y="7" width="3" height="9" /> <rect x="14" y="7" width="3" height="5" />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Now+Next</span>

      <form id="now_task_options" style="display: none;" phx-submit="task_actions">
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
          title="Move Selected Tasks To The Later Pile"
          name="action"
          value="move_to_later"
          class="font-bold rounded"
        >
          <svg
            class="h-6 w-6 text-sky-500 hover:text-sky-400"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" /> <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(60 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(120 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(180 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(240 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(300 12 12)" />
          </svg>
        </button>
      </form>
      <%= if @now_tasks do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for task <- @now_tasks do %>
            <.live_component
              module={PmToolWeb.TaskComponent}
              draggable={task.status == "Unstarted"}
              id={"task-#{task.slug}#{@timestamp}"}
              task={task}
              show_task={if @open_tasks[task.slug], do: "hidden", else: "flex"}
              show_task_edit={if @open_tasks[task.slug], do: "flex", else: "hidden"}
              actions={true}
            />
          <% end %>
        </ul>
      <% end %>
      <%= if @next_tasks do %>
        <%= for {index, current_tasks} <- @next_tasks do %>
          <%= if index == 1 do %>
            <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">
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
      <.live_component
        module={PmToolWeb.TaskComponent}
        id={@new_task_id}
        current_user={@current_user}
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
