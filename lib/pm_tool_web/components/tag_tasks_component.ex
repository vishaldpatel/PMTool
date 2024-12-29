defmodule PmToolWeb.TagTasksComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <button class="font-bold rounded" phx-click="hide_tag_tasks" phx-value-tag={@tag}>
        <svg
          class="h-6 w-6 text-orange-500"
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
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Tag: {@tag}</span>
      <form
        id={"tag_task_options_#{@tag}"}
        class="tag_task_options"
        type="submit"
        style="display: none;"
        phx-submit="remove_tag_from_tasks"
        phx-value-tag={@tag}
      >
        <button class="font-bold rounded">
          <svg
            class="h-6 w-6 text-orange-400"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" /> <line x1="4" y1="7" x2="20" y2="7" />
            <line x1="10" y1="11" x2="10" y2="17" /> <line x1="14" y1="11" x2="14" y2="17" />
            <path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" />
            <path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" />
          </svg>
        </button>
      </form>
      <div
        droppable="true"
        id={"tag-tasks-#{@tag}"}
        class="droppable_tag_target bg-gray-800 rounded-md"
      >
        <input type="hidden" name="tag" class="tag" value={@tag} />
        <h3 class="font-bold text-right text-sm px-2 text-gray-500">Done</h3>
        <ul>
          <%= for task <- @tasks[:Done] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              id={"tag-#{@tag}-task-#{task.slug}#{@timestamp}"}
              tag={@tag}
              task={task}
              no_move={true}
              actions={false}
              hide_tag_tag={true}
            />
          <% end %>
        </ul>
        <h3 class="font-bold text-right text-sm px-2 mt-1 text-gray-500">Now + Next</h3>
        <ul>
          <%= for task <- @tasks[:Now] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              no_move={task.status != "Unstarted"}
              id={"tag-#{@tag}-task-#{task.slug}#{@timestamp}"}
              tag={@tag}
              task={task}
              actions={true}
              hide_tag_tag={true}
            />
          <% end %>
          <%= for task <- @tasks[:Next] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              no_move={task.status != "Unstarted"}
              id={"tag-#{@tag}-task-#{task.slug}#{@timestamp}"}
              tag={@tag}
              task={task}
              actions={true}
              hide_tag_tag={true}
            />
          <% end %>
        </ul>
        <h3 class="font-bold text-right text-sm px-2 mt-1 text-gray-500">Later</h3>
        <ul>
          <%= for task <- @tasks[:Later] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              id={"tag-#{@tag}-task-#{task.slug}#{@timestamp}"}
              tag={@tag}
              task={task}
              no_move={false}
              hide_tag_tag={true}
            />
          <% end %>
        </ul>
      </div>
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
