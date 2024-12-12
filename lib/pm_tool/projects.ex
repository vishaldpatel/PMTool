defmodule PmTool.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo

  alias PmTool.Projects.Project
  alias PmTool.Tasks.Task
  alias PmTool.Projects.TeamProject
  alias PmTool.Projects.ProjectTask
  alias PmTool.Teams.Team
  alias PmTool.Accounts.User

  def list_projects_for(%Team{} = team) do
    query =
      from p in Project,
        join: t in assoc(p, :team_projects),
        where: t.team_id == ^team.id

    Repo.all(query)
  end

  def list_projects_for(%User{} = user) do
    query =
      from p in Project,
        where: p.creator_id == ^user.id

    Repo.all(query)
  end

  def get_project!(id), do: Repo.get!(Project, id)

  def get_projects!(slugs) do
    Repo.all(from p in Project, where: p.slug in ^slugs)
  end

  def get_project_by_slug!(slug), do: Repo.get_by!(Project, slug: slug)

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def add_team_to_project(%Project{} = project, %Team{} = team) do
    %TeamProject{}
    |> TeamProject.changeset(%{project_id: project.id, team_id: team.id})
    |> Repo.insert()
  end

  def add_task_to_project(%Project{} = project, %Task{} = task) do
    %ProjectTask{}
    |> ProjectTask.changeset(%{project_id: project.id, task_id: task.id})
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
end
