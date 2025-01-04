defmodule PmToolWeb.TagComponent do
  use PmToolWeb, :live_component

  def mount(socket) do
    {
      :ok,
      assign(
        socket,
        tag: "",
        color: "text-cyan-200 bg-cyan-800 hover:bg-zinc-700",
        edit_tag: false,
        tag_type: "project",
        tag_slug: nil
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
    if assigns.edit_tag do
      edit_tag(assigns)
    else
      show_tag(assigns)
    end
  end

  defp show_tag(assigns) do
    ~H"""
    <div class="inline">
      <button
        phx-click="tag_clicked"
        phx-value-tag={@tag}
        phx-value-tag-type={@tag_type}
        phx-value-tag-slug={@tag_slug}
        type="button"
        class={
          "mr-[3px] inline-flex items-center px-1 text-xs font-xs italic #{@color} align-text-top mt-0.5" 
        }
      >
        {@tag}
      </button>
    </div>
    """
  end

  defp edit_tag(assigns) do
    ~H"""
    <div>
      <div class="text-sm">{String.capitalize(@type)} Tag</div>
      <div class="tags_outer w-full px-1 mb-1 bg-white border border-gray-500 rounded rounded-sm focus:border-blue-500 cursor-text">
        <input type="hidden" name="tag_type" value={@tag_type} />
        <input type="hidden" name="tag_limit" value={1} />
        <div class="tags inline">
          <div class="tag inline">
            <input type="hidden" name={"#{@type}[tag]"} value={@tag} />
            <button type="button" class={"remove_tag px-1 mb-1 text-xs font-xs #{@color}"}>
              <span>&#10005; &#10072;</span>
              <span class="italic">{@tag}</span>
            </button>
          </div>
        </div>
        <%= if @tag == "" do %>
          <input
            type="text"
            placeholder=""
            class="new_tag_input bg-transparent text-cyan-700 italic border-0 inline text-xs p-0 m-0 w-20 focus:ring-0 cursor-text"
          />
        <% else %>
          <input
            type="text"
            placeholder=""
            class="new_tag_input bg-transparent text-cyan-700 italic border-0 inline text-xs p-0 m-0 w-20 focus:ring-0 cursor-text"
            disabled
          />
        <% end %>
      </div>
    </div>
    """
  end
end
