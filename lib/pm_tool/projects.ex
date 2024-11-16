defmodule PmTool.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo

  alias PmTool.Projects.Project
  alias PmTool.Projects.Member
  alias PmTool.Projects.Epic
  alias PmTool.Accounts.User

  def list_projects() do
    Repo.all(Project)
  end

  def list_projects_for_owner(%User{id: user_id}) do
    Repo.all(from p in Project, where: p.owner_id == ^user_id)
  end

  def list_projects_for_member(%User{id: user_id}) do
    # Get all projects where the user is a member in the members table
    query = from p in Project,
            join: m in Member,
            on: p.id == m.project_id,
            where: m.user_id == ^user_id
    Repo.all(query)
  end

  def get_project!(combo_slug) do 
    url_hash = combo_slug
    |> String.split("--")
    |> List.first()

    Repo.get_by!(Project, url_hash: url_hash)
  end

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  #################
  ## Project Member
  #################

  alias PmTool.Projects.Member

  def list_members do
    Repo.all(Member)
  end

  def list_members_for_project(%Project{id: project_id}) do
    Repo.all(from m in User, join: p in assoc(m, :members), where: p.id == ^project_id)
  end

  def get_member!(id), do: Repo.get!(Member, id)

  def add_member_to_project(%User{} = user, %Project{} = project) do
    %Member{}
    |> Member.changeset(%{user_id: user.id, project_id: project.id})
    |> Repo.insert()
  end

  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  def delete_member(%Member{} = member) do
    Repo.delete(member)
  end

  def change_member(%Member{} = member, attrs \\ %{}) do
    Member.changeset(member, attrs)
  end

  ################
  ## Project Epics
  ################

  def list_epics_for_project(%Project{id: project_id}) do
    Repo.all(from e in Epic, where: e.project_id == ^project_id)
  end

  def get_epic!(url_hash), do: Repo.get_by!(Epic, url_hash)

  def get_epic_by_id!(id), do: Repo.get!(Epic, id)

  def create_epic(attrs \\ %{}) do
    %Epic{}
    |> Epic.changeset(attrs)
    |> Repo.insert()
  end

  def update_epic(%Epic{} = epic, attrs) do
    epic
    |> Epic.changeset(attrs)
    |> Repo.update()
  end
end
