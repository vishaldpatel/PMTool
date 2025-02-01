defmodule PmToolWeb.DoneTasksComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
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
                current_user={@current_user}
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
