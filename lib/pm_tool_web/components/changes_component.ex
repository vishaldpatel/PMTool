defmodule PmToolWeb.ChangesComponent do
  use PmToolWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0">
      <div
        id={"project-tasks-#{@project.slug}"}
        class="droppable_project_target bg-gray-800 rounded-md"
      >
        <ul></ul>
      </div>
    </div>
    """
  end
end
