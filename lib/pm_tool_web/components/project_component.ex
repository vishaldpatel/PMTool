defmodule PmToolWeb.ProjectComponent do
  use PmToolWeb, :live_component

  alias PmTool.Projects
  alias PmTool.Projects.Project

  def render(assigns) do
    if assigns.project.id do
      show_project(assigns)
    else
      new_project(assigns)
    end
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       project: %Project{},
       open_project_slugs: [],
       actions: true,
       show_project: "flex",
       show_project_edit: "hidden"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("update_project", %{"project" => project_params}, socket) do
    if project_params["slug"] == socket.assigns.project.slug do
      timestamp = DateTime.to_unix(DateTime.utc_now())

      case Projects.update_project(socket.assigns.project, project_params) do
        {:ok, %Project{} = updated_project} ->
          send(self(), {:project_updated, updated_project})

          {:noreply,
           assign(socket,
             project: updated_project,
             id: "project-#{updated_project.slug}#{timestamp}",
             show_project: "flex",
             show_project_edit: "hidden"
           )}

        {:error, _changeset} ->
          {:noreply,
           assign(socket,
             show_project: "hidden",
             show_project_edit: "flex"
           )}
      end
    end
  end

  def handle_event("create_project", %{"project" => project_params}, socket) do
    project_params =
      %{
        "creator_id" => socket.assigns.current_user.id,
        "owner_id" => socket.assigns.current_user.id
      }
      |> Enum.into(project_params)

    case Projects.create_project(project_params) do
      {:ok, _project} ->
        send(self(), {:new_project_created})

        {:noreply,
         assign(socket,
           show_project: "flex",
           show_project_edit: "hidden"
         )}

      {:error, _changeset} ->
        {:noreply,
         assign(socket,
           show_project: "hidden",
           show_project_edit: "flex"
         )}
    end
  end

  defp new_project(assigns) do
    ~H"""
    <div>
      <.project_form
        project={@project}
        id={@id}
        action="create_project"
        myself={@myself}
        show_project_edit={@show_project_edit}
      />
    </div>
    """
  end

  def show_project(assigns) do
    ~H"""
    <li class="text-left mt-0.5">
      <div class="inline-block cursor-pointer border border-gray-500 text-right rounded bold flex bg-gray-600 hover:bg-gray-500">
        <div
          id={"show-#{@id}"}
          phx-click={
            JS.toggle_class("flex", to: "#show-#{@id}")
            |> JS.toggle_class("hidden", to: "#show-#{@id}")
            |> JS.toggle_class("hidden", to: "#edit-#{@id}")
            |> JS.toggle_class("flex", to: "#edit-#{@id}")
          }
          class={"inline-block text-md w-full pl-1 pr-1 pt-0.5 text-gray-100 #{@show_project}"}
        >
          <div class="inline-block just_title text-left flex-auto">{@project.name}</div>
          <div class="inline-block flex-none">
            <%= unless Enum.member?(@open_project_slugs, @project.slug) do %>
              <button
                phx-click="show_project_tasks"
                phx-value-project_slug={@project.slug}
                class="font-bold rounded my-1"
              >
                <svg
                  class="h-4 w-4 text-orange-500 bg-gray-600 hover:bg-gray-500 rounded border-0"
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
                  <rect x="7" y="7" width="3" height="9" /> <rect x="14" y="7" width="3" height="5" />
                </svg>
              </button>
            <% end %>
          </div>
        </div>
        <.project_form
          project={@project}
          id={@id}
          action="update_project"
          myself={@myself}
          show_project_edit={@show_project_edit}
        />
      </div>
    </li>
    """
  end

  defp project_form(assigns) do
    save_button_name =
      if assigns.action == "create_project" do
        "Create"
      else
        "Update"
      end

    assigns = assign(assigns, :save_button_name, save_button_name)

    ~H"""
    <div id={"edit-"<>@id} class={"text-left w-full #{@show_project_edit}"}>
      <div class="inline-block w-full bg-gray-200 text-left border border-gray-500 p-1 rounded">
        <form phx-submit={@action} phx-target={@myself}>
          <input
            placeholder="Project Name"
            name="project[name]"
            type="text"
            value={@project.name}
            class="rounded-sm w-full py-0 px-1 mb-1"
          /><br />
          <textarea
            placeholder="Project Description"
            name="project[description]"
            type="text"
            class="rounded-sm w-full py-0 px-1 mb-1"
          ><%= @project.description %></textarea><br />
          <input type="hidden" name="project[slug]" value={@project.slug} />
          <.live_component
            id={"edit-project-tag-#{@id}"}
            module={PmToolWeb.TagComponent}
            tag={@project.tag}
            edit_tag={true}
            type="project"
          />
          <div class="w-full text-right">
            <button
              type="reset"
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
