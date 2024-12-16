defmodule PmToolWeb.LabelsComponent do
  use PmToolWeb, :live_component

  alias PmTool.Labels
  alias PmTool.Labels.Label

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
        <div class="mr-[3px]">
          <button
            type="button"
            class={
              "inline-flex items-center px-1 text-xs font-xs italic #{@color} align-text-top italic" 
            }
          >
            <%= label %>
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp edit_labels(assigns) do
    ~H"""
    <div class="w-full px-1 bg-white border border-gray-500 rounded rounded-sm focus:border-blue-500">
      <%= for label <- @labels do %>
        <div class="inline-block">
          <button
            type="button"
            class={
              "px-1 mb-1 text-xs font-xs #{@color}"
            }
          >
            <span>&#10005; &#10072;</span>
            <span class="italic"><%= label %></span>
          </button>
        </div>
      <% end %>
      <input type="text" placeholder="" class="bg-transparent italic border-0 inline text-xs p-0 m-0 w-20 focus:ring-0" name="label" />
    </div>
    """
  end
end
