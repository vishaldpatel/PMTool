defmodule PmToolWeb.DoneTasksComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80">
      <span class="font-semibold uppercase float-right text-gray-400">Done</span>
      <button 
        class="font-bold rounded">
        <svg class="h-6 w-6 text-orange-500"  width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">  <path stroke="none" d="M0 0h24v24H0z"/>  <rect x="3" y="4" width="18" height="4" rx="2" />  <path d="M5 8v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-10" />  <line x1="10" y1="12" x2="14" y2="12" /></svg>
      </button>

      <%= if @tasks do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for task <- @tasks do %>
            <.live_component module={PmToolWeb.TaskComponents} id={"task-#{task.slug}#{@timestamp}"} task={task} no_move={true} no_check={true} />
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
    socket =
      socket
      |> assign(assigns)
      |> assign(timestamp: DateTime.to_unix(DateTime.utc_now()))
    {:ok, socket}
  end
end
