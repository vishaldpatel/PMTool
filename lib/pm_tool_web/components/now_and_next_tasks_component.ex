defmodule PmToolWeb.NowAndNextTasksComponent do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <button
        class="font-bold rounded"
        phx-click={JS.toggle_class("hidden", to: "#edit-#{@new_task_id}")}
      >
        <svg class="h-6 w-6 text-cyan-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </button>

      <button class="font-bold rounded" phx-click="separate_now_and_next_tasks">
        <svg
          class="h-6 w-6 text-red-500"
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

      <form id="now_task_options" style="display: none;" phx-submit="delete_tasks">
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
      <%= if @now_tasks do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for task <- @now_tasks do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              no_move={task.status != "Unstarted"}
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
              Next Iteration
            </div>
          <% else %>
            <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">
              {index} Iterations
            </div>
          <% end %>
          <ul phx-hook="Sortable" id={"#{@id}-group-#{index}"}>
            <%= for task <- current_tasks do %>
              <.live_component
                module={PmToolWeb.TaskComponents}
                id={"task-#{task.slug}#{@timestamp}"}
                no_move={false}
                task={task}
                show_task={if @open_tasks[task.slug], do: "hidden", else: "flex"}
                show_task_edit={if @open_tasks[task.slug], do: "flex", else: "hidden"}
              />
            <% end %>
          </ul>
        <% end %>
      <% end %>
      <.live_component
        module={PmToolWeb.TaskComponents}
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
