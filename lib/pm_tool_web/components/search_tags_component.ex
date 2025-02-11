defmodule PmToolWeb.SearchTagsComponent do
  use PmToolWeb, :live_component

  def mount(socket) do
    {:ok,
     assign(socket,
       tags: [],
       tag_type: "task"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div id="{@id}">
      <%= if @tags != nil and length(@tags) > 0 do %>
        <span class="font-semibold uppercase align-top ml-1 text-gray-400">Task Tags</span>
      <% end %>
      <div>
        <%= for tag <- @tags do %>
          <.live_component
            module={PmToolWeb.TagComponent}
            id={"tag-#{tag}"}
            tag={tag}
            tag_type={@tag_type}
          />
        <% end %>
      </div>
    </div>
    """
  end
end
