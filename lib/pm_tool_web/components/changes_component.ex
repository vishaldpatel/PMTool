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
      <ul>
        <%= for {start_of_week, changes} <- @changes do %>
          <% change_groups = Enum.group_by(changes, & &1.name) |> Enum.to_list() %>
          <% change_groups =
            Enum.sort(change_groups, fn {_a, al}, {_b, bl} ->
              Enum.map(al, & &1.inserted_at) |> Enum.max() >
                Enum.map(bl, & &1.inserted_at) |> Enum.max()
            end) %>
          <li>
            <div class="text-gray-300 text-xs p-1 text-right uppercase">
              Week of {Date.to_string(start_of_week)}
            </div>
          </li>
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
        <% end %>
      </ul>
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
    }
  end
end
