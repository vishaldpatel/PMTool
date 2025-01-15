defmodule PmToolWeb.DoneTasksComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <form id="done_task_options" style="display: none;" phx-submit="delete_tasks">
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

      <button class="font-bold rounded">
        <svg
          class="h-6 w-6 text-orange-500"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          stroke-width="2"
          stroke="currentColor"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path stroke="none" d="M0 0h24v24H0z" /> <rect x="3" y="4" width="18" height="4" rx="2" />
          <path d="M5 8v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-10" />
          <line x1="10" y1="12" x2="14" y2="12" />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Done</span>

      <%= if @tasks do %>
        <%= for group <- [:last, :two, :three, :earlier] do %>
          <%= if Enum.count(@tasks[group]) > 0 do %>
            <%= case group do %>
              <% :last -> %>
                <div class="font-bold text-gray-400 uppercase text-xs mb-1 mt-[-18px] text-right">
                  Previous Week
                </div>
              <% :earlier -> %>
                <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">{group}</div>
              <% _ -> %>
                <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">
                  {group} weeks ago
                </div>
            <% end %>
          <% end %>
          <ul phx-hook="Sortable" id={"#{@id}-group-#{group}"}>
            <%= for task <- @tasks[group] do %>
              <.live_component
                module={PmToolWeb.TaskComponent}
                id={"task-#{task.slug}#{@timestamp}"}
                task={task}
                draggable={false}
                actions={false}
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
      |> assign(timestamp: DateTime.to_unix(DateTime.utc_now()))

    {:ok, socket}
  end
end
