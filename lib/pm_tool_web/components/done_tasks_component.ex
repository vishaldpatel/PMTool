defmodule PmToolWeb.DoneTasksComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Done</span>
      <button class="align-top mt-1" title="Older Tasks" phx-click="done_tasks_from_older_weeks_requested">
        <svg
          class={"h-4 w-4 #{@prev_color}"}
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="size-6"
        >
          <path d="M9.195 18.44c1.25.714 2.805-.189 2.805-1.629v-2.34l6.945 3.968c1.25.715 2.805-.188 2.805-1.628V8.69c0-1.44-1.555-2.343-2.805-1.628L12 11.029v-2.34c0-1.44-1.555-2.343-2.805-1.628l-7.108 4.061c-1.26.72-1.26 2.536 0 3.256l7.108 4.061Z" />
        </svg>
      </button>
      <button class="align-top mt-1" title="Newer Tasks" phx-click="done_tasks_from_recent_weeks_requested">
        <svg
          class={"h-4 w-4 #{@next_color}"}
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="size-6"
        >
          <path d="M5.055 7.06C3.805 6.347 2.25 7.25 2.25 8.69v8.122c0 1.44 1.555 2.343 2.805 1.628L12 14.471v2.34c0 1.44 1.555 2.343 2.805 1.628l7.108-4.061c1.26-.72 1.26-2.536 0-3.256l-7.108-4.061C13.555 6.346 12 7.249 12 8.689v2.34L5.055 7.061Z" />
        </svg>
      </button>

      <%= if @tasks do %>
        <%= for group <- [:last, :two, :three, :earlier] do %>
          <%= if Enum.count(@tasks[group]) > 0 do %>
            <%= case group do %>
              <% :last -> %>
                <div class="font-bold text-gray-400 uppercase text-xs mb-1 mt-[-12px] text-right">
                  Last Week
                </div>
              <% :earlier -> %>
                <div class="font-bold text-gray-400 uppercase text-xs mb-1 mt-[-12px] text-right">
                  {group}
                </div>
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
                current_user={@current_user}
                selectable={false}
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
      |> assign(
        next_color: case assigns.done_months_ago do
          nil -> "text-gray-400"
          _ -> "text-lime-500 hover:text-lime-200"
        end
      )
      |> assign(
        prev_color: case assigns.tasks |> Map.values() |> List.flatten() |> Enum.count() > 0 do
          false -> "text-gray-400"
          true -> "text-lime-500 hover:text-lime-200"
        end
      )

    {:ok, socket}
  end
end
