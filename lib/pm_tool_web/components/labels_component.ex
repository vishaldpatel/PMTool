defmodule PmToolWeb.LabelsComponent do
  use PmToolWeb, :live_component

  def mount(socket) do
    {
      :ok, 
      assign(
        socket, 
        labels: [], 
        color: "text-cyan-200 bg-cyan-800 hover:bg-zinc-700",
        edit_labels: false
      )
    }
  end

  def update(assigns, socket) do
    {
      :ok,
      assign(socket, assigns)
      |> assign(labels: case assigns.labels do
        nil -> []
        _ -> assigns.labels
      end)
    }
  end

  def render(assigns) do
    if assigns.edit_labels do
      edit_labels(assigns)
    else
      show_labels(assigns)
    end
  end

  defp show_labels(assigns) do
    ~H"""
    <div class="flex flex-row flex-wrap">
      <%= for label <- @labels do %>
        <button
          type="button"
          class={
            "mr-[3px] mb-1 inline-flex items-center px-1 text-xs font-xs italic #{@color} align-text-top italic" 
          }
        >
          <%= label %>
        </button>
      <% end %>
    </div>
    """
  end

  defp edit_labels(assigns) do
    ~H"""
    <div>
      <div class="text-sm">Labels</div>
      <div class="labels_outer w-full px-1 mb-1 bg-white border border-gray-500 rounded rounded-sm focus:border-blue-500 cursor-text">
        <div class="labels inline">
          <%= for label <- @labels do %>
            <div class="label inline">
              <input type="hidden" name="task[labels][]" value={label} />
              <button
                type="button"
                class={"remove_label px-1 mb-1 text-xs font-xs #{@color}"}
              >
                <span>&#10005; &#10072;</span>
                <span class="italic"><%= label %></span>
              </button>
            </div>
          <% end %>
        </div>
        <input type="text" placeholder="" class={"new_label_input bg-transparent text-cyan-700 italic border-0 inline text-xs p-0 m-0 w-20 focus:ring-0"} />
      </div>
    </div>
    """
  end
end
