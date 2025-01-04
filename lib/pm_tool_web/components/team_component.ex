defmodule PmToolWeb.TeamComponent do
  use PmToolWeb, :live_component

  alias PmTool.Teams
  alias PmTool.Teams.Team

  def render(assigns) do
    if assigns.team.id do
      show_team(assigns)
    else
      new_team(assigns)
    end
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       team: %Team{},
       actions: true,
       show_team: "flex",
       show_team_edit: "hidden",
       is_current: false
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("update_team", %{"team" => team_params}, socket) do
    if team_params["slug"] == socket.assigns.team.slug do
      timestamp = DateTime.to_unix(DateTime.utc_now())

      case Teams.update_team(socket.assigns.team, team_params) do
        {:ok, %Team{} = updated_team} ->
          send(self(), {:team_updated, updated_team})

          {:noreply,
           assign(socket,
             team: updated_team,
             id: "team-#{updated_team.slug}#{timestamp}",
             show_team: "flex",
             show_team_edit: "hidden"
           )}

        {:error, _changeset} ->
          {:noreply,
           assign(socket,
             show_team: "hidden",
             show_team_edit: "flex"
           )}
      end
    end
  end

  def handle_event("create_team", %{"team" => team_params}, socket) do
    team_params =
      %{
        "creator_id" => socket.assigns.current_user.id,
        "owner_id" => socket.assigns.current_user.id
      }
      |> Enum.into(team_params)

    case Teams.create_team_for(socket.assigns.current_user, team_params) do
      {:ok, _team} ->
        send(self(), {:new_team_created})

        {:noreply,
         assign(socket,
           show_team: "flex",
           show_team_edit: "hidden"
         )}

      {:error, _changeset} ->
        {:noreply,
         assign(socket,
           show_team: "hidden",
           show_team_edit: "flex"
         )}
    end
  end

  def handle_event("create_team_member", %{"team_member" => team_member_params}, socket) do
    team = Teams.get_team_by_slug!(team_member_params["team_slug"])

    result =
      team_member_params
      |> Map.put("role", "member")
      |> Map.put("team_id", team.id)
      |> Teams.create_team_member()

    case result do
      {:ok, _} ->
        send(self(), {:new_team_member_created})
    end

    {:noreply, socket}
  end

  defp new_team(assigns) do
    ~H"""
    <div>
      <.team_form
        team={@team}
        id={@id}
        action="create_team"
        myself={@myself}
        show_team_edit={@show_team_edit}
      />
    </div>
    """
  end

  def show_team(assigns) do
    team_class =
      if assigns.is_current do
        "inline-block cursor-pointer border border-gray-500 text-right rounded bold w-60 text-gray-700 bg-orange-300 hover:bg-orange-200"
      else
        "inline-block cursor-pointer border border-gray-500 text-right rounded bold w-60 text-gray-100 bg-gray-600 hover:bg-gray-500"
      end

    assigns = assign(assigns, :team_class, team_class)

    ~H"""
    <li class="text-left mt-0.5">
      <div class={@team_class}>
        <div>
          <div
            id={"show-#{@id}"}
            phx-click={
              JS.toggle_class("flex", to: "#show-#{@id}")
              |> JS.toggle_class("hidden", to: "#show-#{@id}")
              |> JS.toggle_class("hidden", to: "#edit-#{@id}")
              |> JS.toggle_class("flex", to: "#edit-#{@id}")
            }
            class={"inline-block text-md w-full pl-1 pr-1 pt-0.5 #{@show_team}"}
          >
            <div class="inline-block just_title text-left flex-auto">{@team.name}</div>
            <div class="inline-block flex-none">
              <button phx-click={JS.toggle_class("hidden", to: "#teammates-#{@id}")}>
                <svg
                  class="h-4 w-4 text-amber-500 hover:text-amber-400 bg-gray-600 hover:bg-gray-500 rounded border-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                  />
                </svg>
              </button>
              <%= if @is_current == true do %>
                <button class="font-bold rounded my-1" phx-click="unset_current_team">
                  <svg
                    class="h-4 w-4 text-orange-700 bg-orange-200 hover:bg-orange-300 rounded border-0"
                    <svg
                    viewBox="0 0 24 24"
                    width="24"
                    height="24"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                    <line x1="9" y1="9" x2="15" y2="15" />
                    <line x1="15" y1="9" x2="9" y2="15" />
                  </svg>
                </button>
              <% else %>
                <button
                  phx-click="set_current_team"
                  phx-value-team_slug={@team.slug}
                  class="font-bold rounded my-1"
                >
                  <svg
                    class="h-4 w-4 text-orange-200 bg-orange-700 hover:bg-orange-500 rounded border-0"
                    <svg
                    viewBox="0 0 24 24"
                    width="24"
                    height="24"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                    <rect x="7" y="7" width="3" height="9" />
                    <rect x="14" y="7" width="3" height="5" />
                  </svg>
                </button>
              <% end %>
            </div>
          </div>
          <.team_form
            team={@team}
            id={@id}
            action="update_team"
            myself={@myself}
            show_team_edit={@show_team_edit}
          />
        </div>
        <div
          id={"teammates-#{@id}"}
          class="border-gray-500 text-right bold bg-gray-200 inline-block w-full hidden"
        >
          <%= for member <- @team.team_members do %>
            <div class="text-md pl-1 pr-1 pt-0.5 text-gray-900 flex">
              <div class="inline-block just_title text-left flex-auto">
                <img
                  class="w-4 h-4 rounded-full inline align-middle mr-[2px] mb-[3px]"
                  src={"/images/team_members/#{member.email}.png"}
                />{member.name}
              </div>
              <div class="inline-block flex-none">
                <button
                  phx-click="show_team_tasks"
                  phx-value-team_slug={@team.slug}
                  phx-value-teammember="Alice Cooper"
                  class="font-bold rounded my-1"
                >
                  <svg
                    class="h-4 w-4 text-orange-200 bg-orange-700 hover:bg-orange-500 rounded border-0"
                    <svg
                    viewBox="0 0 24 24"
                    width="24"
                    height="24"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                    <rect x="7" y="7" width="3" height="9" />
                    <rect x="14" y="7" width="3" height="5" />
                  </svg>
                </button>
              </div>
            </div>
          <% end %>
          <div class="flex-auto w-full px-1 bg-gray-600 text-left">
            <button
              class="font-bold rounded my-1 bg-gray-600 hover:bg-gray-500 rounded p-[1px]"
              phx-click={JS.toggle_class("hidden", to: "#create_team_member-#{@team.slug}")}
            >
              <svg
                class="h-4 w-4 text-lime-500 hover:text-lime-400"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="8.5" cy="7" r="4" /> <line x1="20" y1="8" x2="20" y2="14" />
                <line x1="23" y1="11" x2="17" y2="11" />
              </svg>
            </button>
            <form
              id={"create_team_member-#{@team.slug}"}
              phx-submit="create_team_member"
              phx-target={@myself}
              class="text-right hidden"
            >
              <input
                placeholder="Full Name"
                name="team_member[name]"
                type="text"
                class="rounded-sm w-full py-0 px-1 mb-1"
              />
              <input
                placeholder="email@domain.tld"
                name="team_member[email]"
                type="email"
                class="rounded-sm w-full py-0 px-1 mb-1"
              />
              <input type="hidden" name="team_member[team_slug]" value={@team.slug} />
              <button
                type="reset"
                class="text-gray-100"
                phx-click={JS.toggle_class("hidden", to: "#create_team_member-#{@team.slug}")}
              >
                Cancel
              </button>
              <button
                type="submit"
                class="font-bold rounded my-1 px-2 text-gray-100 bg-lime-600 hover:bg-lime-500 rounded p-[1px]"
              >
                Add
              </button>
            </form>
          </div>
        </div>
      </div>
    </li>
    """
  end

  defp team_form(assigns) do
    save_button_name =
      if assigns.action == "create_team" do
        "Create"
      else
        "Update"
      end

    assigns = assign(assigns, :save_button_name, save_button_name)

    ~H"""
    <div id={"edit-"<>@id} class={"text-left w-full #{@show_team_edit}"}>
      <div class="inline-block w-full bg-gray-200 text-left border border-gray-500 p-1 rounded">
        <form phx-submit={@action} phx-target={@myself}>
          <input
            placeholder="Team Name"
            name="team[name]"
            type="text"
            value={@team.name}
            class="rounded-sm w-full py-0 px-1 mb-1 text-gray-900"
          /><br />
          <input type="hidden" name="team[slug]" value={@team.slug} />
          <div class="w-full text-right">
            <button
              type="reset"
              class="text-gray-900"
              phx-click={
                JS.toggle_class("flex", to: "#edit-#{@id}")
                |> JS.toggle_class("hidden", to: "#edit-#{@id}")
                |> JS.toggle_class("hidden", to: "#show-" <> @id)
                |> JS.toggle_class("flex", to: "#show-#{@id}")
              }
            >
              Cancel
            </button>
            <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold px-2 py-1 ml-1 rounded">
              {@save_button_name}
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
