defmodule PmToolWeb.ProjectTasksComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <span class="font-semibold uppercase float-right text-gray-400">{@project.name}</span>
      <button
        class="font-bold rounded"
        phx-click="hide_project_tasks"
        phx-value-project_slug={@project.slug}
      >
        <svg
          class="h-6 w-6 text-red-500"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <polygon points="7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2" />
          <line x1="15" y1="9" x2="9" y2="15" /> <line x1="9" y1="9" x2="15" y2="15" />
        </svg>
      </button>
      <div droppable="true" id={"project-tasks-#{@project.slug}"} class="droppable_project_target">
        <input type="hidden" name="project_slug" class="project_slug" value={@project.slug} />
        <h3 class="font-bold text-right">Done</h3>
        <ul>
          <%= for task <- @tasks[:Done] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              id={"project-#{@project.slug}-task-#{task.slug}#{@timestamp}"}
              task={task}
              no_move={true}
              actions={false}
            />
          <% end %>
        </ul>
        <h3 class="font-bold text-right">Now + Next</h3>
        <ul>
          <%= for task <- @tasks[:Now] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              no_move={task.status != "Unstarted"}
              id={"project-#{@project.slug}-task-#{task.slug}#{@timestamp}"}
              task={task}
              actions={true}
            />
          <% end %>
          <%= for task <- @tasks[:Next] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              no_move={task.status != "Unstarted"}
              id={"project-#{@project.slug}-task-#{task.slug}#{@timestamp}"}
              task={task}
              actions={true}
            />
          <% end %>
        </ul>
        <h3 class="font-bold text-right">Later</h3>
        <ul>
          <%= for task <- @tasks[:Later] do %>
            <.live_component
              module={PmToolWeb.TaskComponents}
              id={"project-#{@project.slug}-task-#{task.slug}#{@timestamp}"}
              task={task}
              no_move={false}
              actions={false}
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
