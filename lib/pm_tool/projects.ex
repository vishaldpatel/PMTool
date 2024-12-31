defmodule PmTool.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias PmTool.Repo
  alias PmTool.Tasks
  alias PmTool.Teams

  alias PmTool.Projects.Project
  alias PmTool.Projects.TeamProject
  alias PmTool.Teams.Team
  alias PmTool.Accounts.User

  def list_project_tags_for_team_ids(teams) do
    project_tags_query = 
      from t in Tasks.Task,
        where: t.team_id in ^teams,
        select: t.project_tags

    project_tags = Repo.all(project_tags_query) |> List.flatten()
  end

  def list_projects_for(%User{} = user) do
    teams = Teams.list_teams(user)
    project_tags = list_project_tags_for_team_ids(Enum.map(teams, & &1.id))

    query =
      from p in Project,
        where: p.creator_id == ^user.id or p.tag in ^project_tags

    Repo.all(query)
  end

  def get_project!(id), do: Repo.get!(Project, id)

  def get_projects!(slugs) do
    Repo.all(from p in Project, where: p.slug in ^slugs)
  end

  def get_project_by_tag!(tag), do: Repo.get_by!(Project, tag: tag)

  def get_project_by_slug!(slug), do: Repo.get_by!(Project, slug: slug)

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def add_team_to_project(%Project{} = project, %Team{} = team) do
    %TeamProject{}
    |> TeamProject.changeset(%{project_id: project.id, team_id: team.id})
    |> Repo.insert_or_update()
  end

  def update_project(%Project{} = project, attrs) do
    project_changeset = Project.changeset(project, attrs)
    result = Repo.update(project_changeset)

    if changed?(project_changeset, :tag) do
      old_tag = project.tag
      new_tag = project_changeset.changes[:tag]
      Tasks.replace_project_tag(old_tag, new_tag)
    end

    result
  end

  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end
end
