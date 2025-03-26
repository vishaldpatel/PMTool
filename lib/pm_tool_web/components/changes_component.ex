defmodule PmToolWeb.ChangesComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <button
        title={"Hide #{@id}"}
        class="font-bold rounded"
        phx-click="hide_changelog"
        phx-value-changelog-id={@id}
      >
        <svg
          class="h-6 w-6 text-orange-500 hover:text-orange-400"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
          <line x1="9" y1="9" x2="15" y2="15" /> <line x1="15" y1="9" x2="9" y2="15" />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">{@title}</span>
      <button
        class="align-top mt-1"
        title="Previous Week"
        phx-click="changes_for_previous_week_requested"
      >
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
      <button class="align-top mt-1" title="Next Week" phx-click="changes_for_next_week_requested">
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
      <%= for {start_of_week, changes} <- @changes do %>
        <% change_groups = Enum.group_by(changes, & &1.name) |> Enum.to_list() %>
        <% change_groups =
          Enum.sort(change_groups, fn {_a, al}, {_b, bl} ->
            Enum.map(al, & &1.inserted_at) |> Enum.max() >
              Enum.map(bl, & &1.inserted_at) |> Enum.max()
          end) %>
        <div class="font-bold text-gray-400 text-xs mb-1 mt-[-19px] text-right">
          Week of {Date.to_string(start_of_week)}
        </div>
        <ul>
          <%= for {change_group_name, changes} <- change_groups do %>
            <li>
              <div class="text-gray-100 text-sm bg-gray-600 border border-gray-400 border-[1px] p-1 mt-1">
                {change_group_name}
              </div>
            </li>
            <%= for change <- changes do %>
              <li>
                <div class="bg-gray-800">
                  <div class="text-gray-300 text-xs p-1 border border-gray-700 border-[1px]">
                    <% cdt = DateTime.from_naive!(change.inserted_at, "Etc/UTC") %> [{cdt.month}/{cdt.day}, {cdt.hour}:{cdt.minute}] {change.description}
                  </div>
                </div>
              </li>
            <% end %>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(
        next_color:
          if assigns.changes_week_number < 0 do
            "text-lime-500 hover:text-lime-200"
          else
            "text-gray-400"
          end
      )
      |> assign(
        prev_color:
          if not is_nil(assigns.changes) and Enum.count(assigns.changes) > 0 do
            "text-lime-500 hover:text-lime-200"
          else
            "text-gray-400"
          end
      )
    }
  end
end
