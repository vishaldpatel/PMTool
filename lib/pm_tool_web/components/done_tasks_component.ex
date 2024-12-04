defmodule PmToolWeb.DoneTasksComponent do
  use PmToolWeb, :live_component

  alias PmTool.Tasks

  def render(assigns) do
    ~H"""
    <div class="float-left text-left w-80">
      <span class="font-semibold uppercase float-right text-gray-400">Done</span>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, socket}
  end
end
