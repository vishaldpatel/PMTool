defmodule PmToolWeb.TeamsComponent do
  use PmToolWeb, :live_component

  alias PmTool.Teams.Team
  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div class="my-2">
      <button
        class="font-bold rounded"
        title="Make New Team"
        phx-click={JS.toggle_class("hidden", to: "#edit-#{@new_team_id}")}
      >
        <svg
          class="h-6 w-6 text-cyan-500 hover:text-cyan-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Teams</span>

      <%= if not @show_changelog do %>
        <button
          style="float: right; margin-right: 2px;"
          title="Show Changelog"
          phx-click="show_changelog"
        >
          <svg
            class="align-top w-6 h-6 fill-red-500 hover:fill-red-300"
            version="1.1"
            id="Capa_1"
            xmlns="http://www.w3.org/2000/svg"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            width="800px"
            height="800px"
            viewBox="0 0 503.379 503.379"
            xml:space="preserve"
          >
            <g>
              <path d="M458.091,128.116v326.842c0,26.698-21.723,48.421-48.422,48.421h-220.92c-26.699,0-48.421-21.723-48.421-48.421V242.439   c6.907,1.149,13.953,1.894,21.184,1.894c5.128,0,10.161-0.381,15.132-0.969v211.594c0,6.673,5.429,12.104,12.105,12.104h220.92   c6.674,0,12.105-5.432,12.105-12.104V128.116c0-6.676-5.432-12.105-12.105-12.105H289.835c0-12.625-1.897-24.793-5.297-36.315   h125.131C436.368,79.695,458.091,101.417,458.091,128.116z M159.49,228.401c-62.973,0-114.202-51.229-114.202-114.199   C45.289,51.229,96.517,0,159.49,0c62.971,0,114.202,51.229,114.202,114.202C273.692,177.172,222.461,228.401,159.49,228.401z    M159.49,204.19c49.618,0,89.989-40.364,89.989-89.988c0-49.627-40.365-89.991-89.989-89.991   c-49.626,0-89.991,40.364-89.991,89.991C69.499,163.826,109.87,204.19,159.49,204.19z M227.981,126.308   c6.682,0,12.105-5.423,12.105-12.105s-5.423-12.105-12.105-12.105h-56.386v-47.52c0-6.682-5.423-12.105-12.105-12.105   s-12.105,5.423-12.105,12.105v59.625c0,6.682,5.423,12.105,12.105,12.105H227.981z M367.697,224.456h-131.14   c-6.682,0-12.105,5.423-12.105,12.105c0,6.683,5.423,12.105,12.105,12.105h131.14c6.685,0,12.105-5.423,12.105-12.105   C379.803,229.879,374.382,224.456,367.697,224.456z M367.91,297.885h-131.14c-6.682,0-12.105,5.42-12.105,12.105   s5.423,12.105,12.105,12.105h131.14c6.685,0,12.104-5.42,12.104-12.105S374.601,297.885,367.91,297.885z M367.91,374.353h-131.14   c-6.682,0-12.105,5.426-12.105,12.105c0,6.685,5.423,12.104,12.105,12.104h131.14c6.685,0,12.104-5.42,12.104-12.104   C380.015,379.778,374.601,374.353,367.91,374.353z" />
            </g>
          </svg>
        </button>
      <% end %>
      <%= if @teams do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for team <- @teams do %>
            <.live_component
              module={PmToolWeb.TeamComponent}
              id={"team-#{team.slug}"}
              new_team_member_id={"new-team-member-#{team.slug}-#{@timestamp}"}
              current_user={@current_user}
              team={team}
              is_current={@current_team != nil and @current_team.slug == team.slug}
              show_team_members={if Enum.member?(@open_team_slugs, team.slug), do: "", else: "hidden"}
              ,
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
