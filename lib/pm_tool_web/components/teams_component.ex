defmodule PmToolWeb.TeamsComponent do
  use PmToolWeb, :live_component

  alias PmTool.Teams.Team
  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div class="my-2">
      <button
        class="font-bold rounded"
        phx-click={JS.toggle_class("hidden", to: "#edit-" <> @new_team_id)}
      >
        <svg class="h-6 w-6 text-cyan-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Teams</span>

      <%= if @teams do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for team <- @teams do %>
            <.live_component
              module={PmToolWeb.TeamComponent}
              id={"team-#{team.slug}"}
              current_user={@current_user}
              team={team}
              is_current={@current_team != nil and @current_team.slug == team.slug}
            />
          <% end %>
        </ul>
      <% end %>
      <.live_component
        module={PmToolWeb.TeamComponent}
        id={@new_team_id}
        current_user={@current_user}
        team={%Team{}}
      />
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

    {:ok, socket}
  end
end
