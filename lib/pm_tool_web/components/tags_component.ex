defmodule PmToolWeb.TagsComponent do
  use PmToolWeb, :live_component

  def mount(socket) do
    {
      :ok, 
      assign(
        socket, 
        tags: [], 
        color: "text-cyan-200 bg-cyan-800 hover:bg-zinc-700",
        edit_tags: false,
        tag_type: "task"
      )
    }
  end

  def update(assigns, socket) do
    {
      :ok,
      assign(socket, assigns)
      |> assign(tags: case assigns.tags do
        nil -> []
        _ -> assigns.tags
      end)
    }
  end

  def render(assigns) do
    if assigns.edit_tags do
      edit_tags(assigns)
    else
      show_tags(assigns)
    end
  end

  defp show_tags(assigns) do
    ~H"""
    <div class="flex flex-row flex-wrap">
      <%= for tag <- @tags do %>
        <button
          type="button"
          class={
            "mr-[3px] mb-1 inline-flex items-center px-1 text-xs font-xs italic #{@color} align-text-top italic" 
          }
        >
          <%= tag %>
        </button>
      <% end %>
    </div>
    """
  end

  defp edit_tags(assigns) do
    ~H"""
    <div>
      <div class="text-sm">{String.capitalize(@tag_type)} Tags</div>
      <div class="tags_outer w-full px-1 mb-1 bg-white border border-gray-500 rounded rounded-sm focus:border-blue-500 cursor-text">
        <input type="hidden" name="tag_type" value={@tag_type} />
        <input type="hidden" name="tag_limit" value={0} />
        <div class="tags inline">
          <%= for tag <- @tags do %>
            <div class="tag inline">
              <input type="hidden" name={"#{@tag_type}[tags][]"} value={tag} />
              <button
                type="button"
                class={"remove_tag px-1 mb-1 text-xs font-xs #{@color}"}
              >
                <span>&#10005; &#10072;</span>
                <span class="italic"><%= tag %></span>
              </button>
            </div>
          <% end %>
        </div>
        <input type="text" placeholder="" class={"new_tag_input bg-transparent text-cyan-700 italic border-0 inline text-xs p-0 m-0 w-20 focus:ring-0"} />
      </div>
    </div>
    """
  end
end
