defmodule PmToolWeb.TeamMemberComponent do
  use PmToolWeb, :live_component

  alias PmTool.Teams
  alias PmTool.Teams.TeamMember

  def render(assigns) do
    if assigns.team_member.id do
      show_team_member(assigns)
    else
      new_team_member(assigns)
    end
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       show_team_member: "flex",
       show_team_member_edit: "hidden"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("update_team_member", %{"team_member" => team_member_params}, socket) do
    timestamp = DateTime.to_unix(DateTime.utc_now())
    team = Teams.get_team_by_slug!(team_member_params["team_slug"])

    if team.id == socket.assigns.team.id do
      case Teams.update_team_member(
             socket.assigns.team_member,
             Map.put(team_member_params, "team_id", team.id)
           ) do
        {:ok, %TeamMember{} = updated_team_member} ->
          {:noreply,
           assign(socket,
             team: socket.assigns.team,
             team_member: updated_team_member,
             id: "team-member-#{team.slug}#{timestamp}",
             show_team_member: "flex",
             show_team_member_edit: "hidden"
           )}

        {:error, _changeset} ->
          {:noreply,
           assign(socket,
             show_team_member: "hidden",
             show_team_member_edit: "flex"
           )}
      end
    else
      {:noreply,
       assign(socket,
         show_team_member: "hidden",
         show_team_member_edit: "flex"
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

  def handle_event("delete_team_member", team_member_params, socket) do
    team_member = Teams.get_team_member!(team_member_params["id"])

    if team_member.id == socket.assigns.team_member.id do
      Teams.remove_team_member(team_member)
      send(self(), {:team_member_deleted})
    end

    {:noreply, socket}
  end

  defp new_team_member(assigns) do
    ~H"""
    <div>
      <.team_member_form
        team={@team}
        team_member={@team_member}
        id={@id}
        action="create_team_member"
        myself={@myself}
        show_team_member_edit={@show_team_member_edit}
      />
    </div>
    """
  end

  defp show_team_member(assigns) do
    ~H"""
    <div>
      <div
        class="text-md pl-1 pr-1 pt-0.5 text-gray-900 flex"
        id={"show-#{@id}"}
        phx-click={
          JS.toggle_class("flex", to: "#show-#{@id}")
          |> JS.toggle_class("hidden", to: "#show-#{@id}")
          |> JS.toggle_class("hidden", to: "#edit-#{@id}")
          |> JS.toggle_class("flex", to: "#edit-#{@id}")
        }
      >
        <div class="inline-block just_title text-left flex-auto">
          <img
            class="w-4 h-4 rounded-full inline align-middle mr-[2px] mb-[3px]"
            src={"/images/team_members/#{@team_member.email}.png"}
          />{@team_member.name}
        </div>
        <div class="inline-block flex-none">
          <!-- <button
            phx-click="show_team_member_tasks"
            phx-value-team_slug={@team.slug}
            phx-value-teammember_id={@team_member.id}
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
          </button> -->
        </div>
      </div>
      <.team_member_form
        team={@team}
        team_member={@team_member}
        id={@id}
        action="update_team_member"
        myself={@myself}
        show_team_member_edit={@show_team_member_edit}
      />
    </div>
    """
  end

  defp team_member_form(assigns) do
    save_button_name =
      if assigns.action == "create_team_member" do
        "Add"
      else
        "Update"
      end

    assigns = assign(assigns, :save_button_name, save_button_name)

    ~H"""
    <div id={"edit-#{@id}"} class={"text-left w-full #{@show_team_member_edit}"}>
      <form phx-submit={@action} phx-target={@myself} class="text-right text-gray-900">
        <input
          placeholder="Full Name"
          name="team_member[name]"
          value={@team_member.name}
          type="text"
          class="rounded-sm w-full py-0 px-1 mb-1"
        />
        <input
          placeholder="email@domain.tld"
          name="team_member[email]"
          value={@team_member.email}
          type="email"
          class="rounded-sm w-full py-0 px-1 mb-1"
        />
        <input type="hidden" name="team_member[role]" value="member" />
        <input type="hidden" name="team_member[team_slug]" value={@team.slug} />
        <input type="hidden" name="team_member[id]" value={@team_member.id} />
        <%= if @team_member.id do %>
          <button
            title={"Remove #{@team_member.name} from #{@team.name}"}
            type="button"
            phx-click={JS.toggle_class("hidden", to: "#delete-#{@id}")}
            class="float-left mt-2 ml-1"
          >
            <svg
              class="h-4 w-4 text-red-600 hover:text-red-400"
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
          <button
            type="button"
            title={"Confirm removal of #{@team_member.name} from #{@team.name}"}
            id={"delete-#{@id}"}
            phx-click="delete_team_member"
            phx-value-id={@team_member.id}
            phx-target={@myself}
            class="float-left mt-2 ml-1 hidden"
          >
            <svg
              class="h-4 w-4 text-green-600 hover:text-green-400"
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
        <% end %>
        <button
          type="reset"
          class="text-red-500 hover:text-red-400"
          phx-click={
            JS.toggle_class("flex", to: "#edit-#{@id}")
            |> JS.toggle_class("hidden", to: "#edit-#{@id}")
            |> JS.toggle_class("hidden", to: "#show-#{@id}")
            |> JS.toggle_class("flex", to: "#show-#{@id}")
          }
        >
          Cancel
        </button>
        <button
          type="submit"
          class="font-bold rounded my-1 px-2 mr-1 text-gray-100 bg-lime-600 hover:bg-lime-500 rounded p-[1px]"
        >
          {@save_button_name}
        </button>
      </form>
    </div>
    """
  end
end
