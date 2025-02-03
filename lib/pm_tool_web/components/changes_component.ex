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
        <% changes =
          Enum.reduce(@changes, [{false, %{name: nil}}], fn x, acc ->
            [{_is_same, c} | _] = acc
            [{x.name == c.name, x} | acc]
          end) %>
        <%= for {is_same, change} <- Enum.reverse(changes) do %>
          <%= if change.name != nil do %>
            <li>
              <div class="bg-gray-800">
                <%= if not is_same do %>
                  <div class="text-gray-100 text-sm bg-gray-600 border border-gray-400 border-[1px] p-1 mt-1">
                    {change.name}
                  </div>
                <% end %>
                <div class="text-gray-300 text-xs p-1 border border-gray-700 border-[1px]">
                  {change.inserted_at} | {change.description}
                </div>
              </div>
            </li>
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
